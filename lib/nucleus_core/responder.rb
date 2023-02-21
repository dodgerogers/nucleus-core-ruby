require "set"

module NucleusCore
  class Responder
    attr_reader :response_adapter, :request_adapter, :request

    def initialize(request_adapter: nil, response_adapter: nil)
      @request_adapter = request_adapter
      @response_adapter = response_adapter
      @request = nil
    end

    # rubocop:disable Lint/RescueException:
    def execute(raw_request=nil, &block)
      return if block.nil?

      @request = init_request!(raw_request)
      entity = proc_to_lambda(&block).call(@request)

      render_entity(entity)
    rescue Exception => e
      handle_exception(e)
    end
    # rubocop:enable Lint/RescueException:

    def init_request!(raw_request=nil)
      attributes = request_adapter&.call(raw_request) || {}

      NucleusCore::RequestAdapter.new(attributes)
    end

    # Calling `return` in a block/proc returns from the outer calling scope as well.
    # Lambdas do not have this limitation. So we convert the proc returned
    # from a block method into a lambda to avoid 'return' exiting the method early.
    # https://stackoverflow.com/questions/2946603/ruby-convert-proc-to-lambda
    def proc_to_lambda(&block)
      define_singleton_method(:_proc_to_lambda_, &block)

      method(:_proc_to_lambda_).to_proc
    end

    def render_entity(entity)
      return handle_context(entity) if entity.is_a?(NucleusCore::Operation::Context)
      return render_view(entity) if subclass_of(entity, NucleusCore::View)
      return render_response(entity) if subclass_of(entity, NucleusCore::ResponseAdapter)
    end

    def handle_exception(exception)
      logger(exception)

      status = exception_to_status(exception)
      attrs = { message: exception.message, status: status }
      error = NucleusCore::ErrorView.new(attrs)

      render_entity(error)
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      message = context.message
      attrs = { message: message, status: :unprocessable_entity }
      view = NucleusCore::ErrorView.new(attrs)

      render_view(view)
    end

    def render_view(view)
      render_to_format = "#{@request.format}_response".to_sym
      format_response = view.send(render_to_format) if view.respond_to?(render_to_format)

      raise NucleusCore::BadRequest, "`#{@request.format}` is not supported" if format_response.nil?

      render_response(format_response)
    end

    def render_response(entity)
      render_headers(entity.headers)

      render_method = {
        NucleusCore::JsonResponse => :render_json,
        NucleusCore::XmlResponse => :render_xml,
        NucleusCore::PdfResponse => :render_pdf,
        NucleusCore::CsvResponse => :render_csv,
        NucleusCore::TextResponse => :render_text,
        NucleusCore::NoResponse => :render_nothing
      }.fetch(entity.class, nil)

      response_adapter&.send(render_method, entity)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, v|
        formatted_key = k.titleize.gsub(/\s *|_/, "-")

        response_adapter&.set_header(formatted_key, v)
      end
    end

    def exception_to_status(exception)
      exceptions = NucleusCore.configuration.exceptions

      case exception
      when NucleusCore::NotFound, *exceptions.not_found
        :not_found
      when NucleusCore::BadRequest, *exceptions.bad_request
        :bad_request
      when NucleusCore::NotAuthorized, *exceptions.forbidden
        :forbidden
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
