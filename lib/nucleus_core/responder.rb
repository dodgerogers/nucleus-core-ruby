require "set"

module NucleusCore
  # The Responder class is responsible for managing the lifecycle of a request-response
  # interaction within the NucleusCore framework. It serves as a bridge between the
  # incoming request and the outgoing response, handling the request processing, entity
  # rendering, and error handling.
  #
  # Purpose:
  # - To adapt and process the incoming request using the provided request adapter.
  # - To capture the response entity and render it appropriately based on its type.
  # - To handle exceptions that occur during the request processing and render appropriate
  #   error responses.
  #
  # Key Responsibilities:
  # - Initializing with request and response adapters.
  # - Executing the main request handling logic within a block, capturing the context,
  #   and rendering the resulting entity.
  # - Rendering different types of entities, such as views and operation contexts.
  # - Handling exceptions and rendering error views based on the type of exception.
  #
  # Attributes:
  # - `request_adapter`: Adapter used to process the incoming request.
  # - `response_adapter`: Adapter used to render the outgoing response.
  # - `request_context`: Context of the current request, containing request-specific
  #   attributes and data.
  #
  # Methods:
  # - `initialize`: Sets up the responder with the given request and response adapters.
  # - `execute`: Executes the request handling logic within a block and renders the
  #   resulting entity. Handles any exceptions that occur.
  # - `render_entity`: Renders the given entity based on its type (context, view, view
  #   response, or nil).
  # - `handle_context`: Renders the appropriate view based on the success or failure of
  #   the given context.
  # - `render_nothing`: Renders an empty response.
  # - `render_view`: Renders a view based on the request format.
  # - `render_view_response`: Sends the view response using the response adapter.
  # - `handle_exception`: Logs and renders an error view based on the exception type.
  # - `render_headers`: Sets the response headers using the response adapter.
  # - `exception_to_status`: Maps exceptions to HTTP status codes.
  # - `logger`: Logs messages using the configured logger.
  #
  # Note:
  # - This class relies on external adapters and configurations provided by the
  #   NucleusCore framework to function correctly.
  #
  class Responder
    attr_accessor :response_adapter, :request_adapter, :request_context

    def initialize(request_adapter: nil, response_adapter: nil)
      @request_adapter = request_adapter
      @response_adapter = response_adapter
      @request_context = nil
    end

    # rubocop:disable Lint/RescueException:
    def execute(raw_request_context=nil, &block)
      return if block.nil?

      request_context_attrs = request_adapter&.call(raw_request_context) || {}
      @request_context = NucleusCore::RequestAdapter.new(request_context_attrs)
      entity = Utils.capture(@request_context, &block)

      render_entity(entity)
    rescue Exception => e
      handle_exception(e)
    end
    # rubocop:enable Lint/RescueException:

    def render_entity(entity)
      return handle_context(entity) if entity.is_a?(NucleusCore::Operation::Context)
      return render_view(entity) if Utils.subclass_of(entity, NucleusCore::View)
      return render_view_response(entity) if Utils.subclass_of(entity, NucleusCore::View::Response)
      return render_nothing if entity.nil?
    end

    def handle_context(context)
      return render_nothing if context.success?
      return handle_exception(context.exception) if context.exception

      view = NucleusCore::ErrorView.new(message: context.message, status: :internal_server_error)

      render_view(view)
    end

    def render_nothing
      view_response = NucleusCore::View::Response.new(:nothing)

      render_view_response(view_response)
    end

    def render_view(view)
      view_format = request_context.format.to_sym
      view_response = view.send(view_format) if view.respond_to?(view_format)

      if view_response.nil?
        requested_format = request_context.format
        default_response_format = NucleusCore.configuration.default_response_format || :json

        request_context.to_h[:format] = default_response_format

        raise NucleusCore::BadRequest, "`#{requested_format}` is not supported"
      end

      render_view_response(view_response)
    end

    def render_view_response(view_response)
      render_headers(view_response.headers)

      response_adapter&.send(view_response.format, view_response)
    end

    def handle_exception(exception)
      logger(exception, :error)

      status = exception_to_status(exception)
      view = NucleusCore::ErrorView.new(message: exception.message, status: status)

      render_view(view)
    end

    def render_headers(headers={})
      raise NotImplementedError unless response_adapter.respond_to?(:set_header)

      (headers || {}).each do |k, v|
        formatted_key = k.gsub(/\s *|_/, "-")

        response_adapter&.set_header(formatted_key, v)
      end
    end

    def exception_to_status(exception)
      exceptions = NucleusCore.configuration.request_exceptions

      case exception
      when NucleusCore::NotFound, *exceptions.not_found
        :not_found
      when NucleusCore::BadRequest, *exceptions.bad_request
        :bad_request
      when NucleusCore::Unauthorized, *exceptions.forbidden
        :forbidden
      when NucleusCore::NotAuthenticated, *exceptions.unauthorized
        :unauthorized
      when NucleusCore::Unprocessable, *exceptions.unprocessable
        :unprocessable_entity
      else
        :internal_server_error
      end
    end

    def logger(object, log_level=:info)
      NucleusCore.configuration.logger&.send(log_level, object)
    end
  end
end
