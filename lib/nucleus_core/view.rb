require "nucleus_core/entity"

module NucleusCore
  class View < NucleusCore::Entity
    class Response < NucleusCore::Entity
      def initialize(format, attrs={})
        status = status_code(attrs[:status])

        super(attrs.merge!(format: format, status: status))
      end

      private

      def status_code(status=nil)
        status = Utils.status_code(status)

        status.zero? ? 200 : status
      end
    end

    def json
      build_response(content: to_h)
    end

    private

    # Creates a new `NucleusCore::View::Response` object with the given format and attributes.
    #
    # @param request_format [Symbol] The format of the response (e.g., `:html`, `:json`).
    #   Defaults to the name of the calling method if not provided.
    # @param attrs [Hash] Additional attributes for the response.
    #
    # @return [NucleusCore::View::Response] A new response object.
    #
    # @example Default format (inferred from caller)
    #   def show
    #     build_response(title: "Example")
    #     # Equivalent to build_response(request_format: :show, title: "Example")
    #   end
    #
    # @example Explicit format
    #   build_response(request_format: :show, data: { foo: "bar" })
    #
    def build_response(request_format: caller_locations(1, 1).first.label.to_sym, **attrs)
      NucleusCore::View::Response.new(request_format, attrs || {})
    end
  end
end
