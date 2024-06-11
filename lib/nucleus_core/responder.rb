require "set"

module NucleusCore
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
      view_format = "#{request_context.format}_response".to_sym
      view_response = view.send(view_format) if view.respond_to?(view_format)

      raise NucleusCore::BadRequest, "`#{request_context.format}` is not supported" if view_response.nil?

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
