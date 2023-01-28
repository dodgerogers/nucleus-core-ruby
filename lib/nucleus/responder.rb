require "nucleus/rack"

module Nucleus
  class Responder
    # what if this isn't rails???
    # def set_request_format(format='json')
    #   @format = format.to_sym
    # end
    # rescue_from Exception, with: :handle_exception

    def request_format
      @format
    end

    # rubocop:disable Lint/RescueException:
    def self.handle_response(&block)
      entity = proc_to_lambda(&block)

      render_entity(entity)
    rescue Exception => e
      handle_exception(e)
    end
    # rubocop:enable Lint/RescueException:

    # TODO: Nucleus.configuration.logger.error(exception)
    def handle_exception(exception)
      config = Nucleus.configuration.responder.exceptions
      status = exception_to_status(exception, config)
      attrs = { message: exception.message, status: status }
      error = Nucleus::Errors::View.new(attrs)
      
      render_entity(error)
    end
    
    private

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
      return render_response(entity) if subclass_of(entity, Nucleus::Response)
    end

    def render_view(view, _status)
      format_method = "#{request_format}_response".to_sym
      implements_format = if view.respond_to?(format_method)
      format_response = view.send(format_method) if implements_format
      format_response = view.json_response if !implements_format

      render_response(format_response)
    end

    def render_response(entity)
      render_headers(entity.headers)

      data_stream_request = entity.class.in?([Nucleus::Pdf::Response, Nucleus::Csv::Response])
      json_request = entity.is_a?(Nucleus::Json::Response)
      xml_request = entity.is_a?(Nucleus::Xml::Response)
      text_request = entity.is_a?(Nucleus::Text::Response)

      return render_data_stream(entity) if data_stream_request
      return render_json(entity) if json_request
      return render_xml(entity) if xml_request
      return render_text(entity) if text_request
    end

    def handle_context(context)
      return render_nothing(context) if context.success?
      return handle_exception(context.exception) if context.exception

      attrs = { message: context.message, status: :unprocessable_entity }
      error_view = Nucleus::Errors::View.new(attrs)

      render_view(error_view)
    end

    def render_headers(headers={})
      (headers || {}).each do |k, v|
        formatted_key = k.titleize.gsub(/\s *|_/, "-")

        response.set_header(formatted_key, v)
      end
    end

    # TODO: adaptation methods to framework
    def render_data_stream(entity)
    end

    def render_json(entity)
    end

    def render_xml(entity)
    end

    def render_text(entity)
    end

    def render_nothing(entity)
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
      entity.class.ancestors.to_set.intersect?(classes.to_set)
    end
  end
end
