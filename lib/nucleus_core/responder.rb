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
      return render_view(entity) if subclass_of(entity, NucleusCore::View)
      return render_response_adapter(entity) if subclass_of(entity, NucleusCore::ResponseAdapter)
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      view = NucleusCore::ErrorView.new(message: context.message, status: :internal_server_error)

      render_view(view)
    end

    def render_view(view)
      format_render_method = "#{request_context.format}_response".to_sym
      response_adapter = view.send(format_render_method) if view.respond_to?(format_render_method)

      raise NucleusCore::BadRequest, "`#{request_context.format}` is not supported" if response_adapter.nil?

      render_response_adapter(response_adapter)
    end

    def render_response_adapter(entity)
      render_headers(entity.headers)

      render_method = "render_#{request_context.format}"

      response_adapter&.send(render_method, entity)
    end

    def handle_exception(exception)
      logger(exception, :error)

      status = exception_to_status(exception)
      view = NucleusCore::ErrorView.new(message: exception.message, status: status)

      render_view(view)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, v|
        formatted_key = k.titleize.gsub(/\s *|_/, "-")

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

    def subclass_of(entity, *classes)
      Set[*entity.class.ancestors].intersect?(classes.to_set)
    end

    def logger(object, log_level=:info)
      NucleusCore.configuration.logger&.send(log_level, object)
    end
  end
end
