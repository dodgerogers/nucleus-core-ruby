require "set"

module Nucleus
  module Responder
    # TODO: Framework specific mixin
    # rescue_from Exception do |exception|
    #   Nucleus::Responder.handle_exception(exception)
    # end

    def set_request_format(format="json")
      @format = format.to_sym
    end

    def request_format
      @format ||= set_request_format
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
      # TODO: Nucleus.configuration.logger.error(exception)

      config = Nucleus.configuration.responder.exceptions
      status = exception_to_status(exception, config)
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
      return render_view(entity) if subclass_of(entity, Nucleus::View)
      return render_response(entity) if subclass_of(entity, Nucleus::ResponseAdapter)
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      attrs = { message: context.message, status: :unprocessable_entity }
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

      framework_adapter = Nucleus.configuration.responder.adapter

      framework_adapter&.send(render_method, entity)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, v|
        formatted_key = k.titleize.gsub(/\s *|_/, "-")

        response.set_header(formatted_key, v)
      end
    end

    # rubocop:disable Lint/DuplicateBranch
    def exception_to_status(exception, config)
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
  end
end
