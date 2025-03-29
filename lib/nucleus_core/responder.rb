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
  # - `infer_status`: Maps exceptions to HTTP status codes.
  # - `logger`: Logs messages using the configured logger.
  #
  # Note:
  # - This class relies on external adapters and configurations provided by the
  #   NucleusCore framework to function correctly.
  #
  class Responder
    EXCEPTION_STATUS_MAP = {
      NucleusCore::NotFound => :not_found,
      NucleusCore::BadRequest => :bad_request,
      NucleusCore::Unauthorized => :forbidden,
      NucleusCore::NotAuthenticated => :unauthorized,
      NucleusCore::Unprocessable => :unprocessable_entity
    }.tap do |map|
      NucleusCore
        .configuration
        .request_exceptions
        .each_pair do |status_name, exceptions|
          exceptions.each { map[_1] = status_name }
        end
    end.freeze

    attr_accessor :response_adapter, :request_adapter, :request_context

    def initialize(request_adapter: nil, response_adapter: nil)
      @request_adapter = request_adapter
      @response_adapter = response_adapter
      @request_context = nil
    end

    # rubocop:disable Lint/RescueException:
    def execute(raw_req_context=nil, &block)
      return if block.nil?

      @request_context = NucleusCore::RequestAdapter.new(request_adapter&.call(raw_req_context) || {})
      entity = Utils.capture(@request_context, &block)

      render_entity(entity)
    rescue Exception => e
      handle_exception(e)
    end
    # rubocop:enable Lint/RescueException:

    def render_entity(entity)
      superclasses = Utils.superclasses(entity)

      case entity
      when NucleusCore::Operation::Context then handle_context(entity)
      when ->(_e) { superclasses.member?(NucleusCore::View) } then render_view(entity)
      when ->(_e) { superclasses.member?(NucleusCore::View::Response) } then render_view_response(entity)
      else render_nothing
      end
    end

    def handle_context(context)
      return render_nothing if context.success?
      return handle_exception(context.exception) if context.exception

      render_view(init_error_view(context.message))
    end

    def render_nothing
      view_response = NucleusCore::View::Response.new(:nothing)

      render_view_response(view_response)
    end

    def render_view(view)
      view_format = request_context.format.to_sym
      view_response = view.send(view_format)

      return render_view_response(view_response) if view_response

      requested_format = request_context.format
      request_context.format = NucleusCore.configuration.default_response_format || :json

      raise NucleusCore::BadRequest, "`#{requested_format}` is not supported"
    end

    def render_view_response(view_response)
      response_adapter.call(view_response)
    end

    def handle_exception(exception)
      logger(exception, :error)

      render_view(
        init_error_view(
          exception.message, infer_status(exception)
        )
      )
    end

    def infer_status(exception)
      EXCEPTION_STATUS_MAP[exception.class] || :internal_server_error
    end

    def logger(object, log_level=:info)
      NucleusCore.configuration.logger&.send(log_level, object)
    end

    def init_error_view(message, status=:internal_server_error)
      NucleusCore::ErrorView.new(message: message, status: status)
    end
  end
end
