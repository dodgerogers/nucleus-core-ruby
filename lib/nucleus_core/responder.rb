require "set"

module NucleusCore
  module Responder
    attr_reader :request_format, :response_adapter

    def init_responder(request_format: nil, response_adapter: nil)
      set_request_format(request_format)
      set_response_adapter(response_adapter)
    end

    def set_request_format(request=nil)
      @request_format = request&.to_sym || :json
    end

    # rubocop:disable Naming/AccessorMethodName
    def set_response_adapter(response_adapter)
      @response_adapter = response_adapter
    end
    # rubocop:enable Naming/AccessorMethodName

    # rubocop:disable Lint/RescueException:
    def handle_response(&block)
      entity = proc_to_lambda(&block)

      render_entity(entity)
    rescue Exception => e
      handle_exception(e)
    end
    # rubocop:enable Lint/RescueException:

    def handle_exception(exception)
      logger(exception)

      status = exception_to_status(exception)
      attrs = { message: exception.message, status: status }
      error = NucleusCore::ErrorView.new(attrs)

      render_entity(error)
    end

    # Calling `return` in a block/proc returns from the outer calling scope as well.
    # Lambdas do not have this limitation. So we convert the proc returned
    # from a block method into a lambda to avoid 'return' exiting the method early.
    # https://stackoverflow.com/questions/2946603/ruby-convert-proc-to-lambda
    def proc_to_lambda(&block)
      define_singleton_method(:_proc_to_lambda_, &block)

      method(:_proc_to_lambda_).to_proc.call
    end

    def render_entity(entity)
      return handle_context(entity) if entity.is_a?(NucleusCore::Operation::Context)
      return render_response(entity) if subclass_of(entity, NucleusCore::ResponseAdapter)
      return render_view(entity) if subclass_of(entity, NucleusCore::View)
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      message = context.message
      attrs = { message: message, status: :unprocessable_entity }
      error_view = NucleusCore::ErrorView.new(attrs)

      render_view(error_view)
    end

    def render_view(view)
      format_rendering = "#{request_format}_response".to_sym
      renders_format = view.respond_to?(format_rendering)
      format_response = view.send(format_rendering) if renders_format

      raise NucleusCore::BadRequest, "#{request_format} is not supported" if format_response.nil?

      render_response(format_response)
    end

    def render_response(entity)
      render_headers(entity.headers)

      method_name = {
        NucleusCore::JsonResponse => :render_json,
        NucleusCore::XmlResponse => :render_xml,
        NucleusCore::PdfResponse => :render_pdf,
        NucleusCore::CsvResponse => :render_csv,
        NucleusCore::TextResponse => :render_text,
        NucleusCore::NoResponse => :render_nothing
      }.fetch(entity.class, nil)

      response_adapter&.send(method_name, entity)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, v|
        formatted_key = k.titleize.gsub(/\s *|_/, "-")

        response_adapter&.set_header(formatted_key, v)
      end
    end

    # rubocop:disable Lint/DuplicateBranch
    def exception_to_status(exception)
      config = exception_map

      case exception
      when NucleusCore::NotFound, *config.not_found
        :not_found
      when NucleusCore::BadRequest, *config.bad_request
        :bad_request
      when NucleusCore::NotAuthorized, *config.forbidden
        :forbidden
      when NucleusCore::Unprocessable, *config.unprocessable
        :unprocessable_entity
      when NucleusCore::BaseException, *config.server_error
        :internal_server_error
      else
        :internal_server_error
      end
    end
    # rubocop:enable Lint/DuplicateBranch

    def subclass_of(entity, *classes)
      Set[*entity.class.ancestors].intersect?(classes.to_set)
    end

    def logger(object, log_level=:info)
      NucleusCore.configuration.logger&.send(log_level, object)
    end

    def exception_map
      NucleusCore.configuration.exceptions_map
    end
  end
end
