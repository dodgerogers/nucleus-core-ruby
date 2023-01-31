require "set"

module Nucleus
  module Responder
    def set_request_format(request=nil)
      @request_format = request&.format&.to_sym || :json
    end

    def request_format
      @request_format ||= set_request_format
    end

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
      error = Nucleus::ErrorView.new(attrs)

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
      return handle_context(entity) if entity.is_a?(Nucleus::Operation::Context)
      return render_response(entity) if subclass_of(entity, Nucleus::ResponseAdapter)
      return render_view(entity) if subclass_of(entity, Nucleus::View)
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      message = context.message
      attrs = { message: message, status: :unprocessable_entity }
      error_view = Nucleus::ErrorView.new(attrs)

      render_view(error_view)
    end

    def render_view(view)
      format_rendering = "#{request_format}_response".to_sym
      renders_format = view.respond_to?(format_rendering)
      format_response = view.send(format_rendering) if renders_format

      raise Nucleus::BadRequest, "#{request_format} is not supported" if format_response.nil?

      render_response(format_response)
    end

    def render_response(entity)
      render_headers(entity.headers)

      render_method = {
        Nucleus::JsonResponse => :render_json,
        Nucleus::XmlResponse => :render_xml,
        Nucleus::PdfResponse => :render_pdf,
        Nucleus::CsvResponse => :render_csv,
        Nucleus::TextResponse => :render_text,
        Nucleus::NoResponse => :render_nothing
      }.fetch(entity.class, nil)

      response_adapter&.send(render_method, entity)
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
      when Nucleus::NotFound, *config.not_found
        :not_found
      when Nucleus::BadRequest, *config.bad_request
        :bad_request
      when Nucleus::NotAuthorized, *config.forbidden
        :forbidden
      when Nucleus::Unprocessable, *config.unprocessable
        :unprocessable_entity
      when Nucleus::BaseException, *config.server_error
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
      Nucleus.configuration.logger&.send(log_level, object)
    end

    def exception_map
      Nucleus.configuration.exceptions_map
    end

    def response_adapter
      Nucleus.configuration.response_adapter
    end
  end
end
