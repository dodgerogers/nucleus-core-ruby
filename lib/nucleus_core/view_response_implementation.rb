module NucleusCore
  class ViewResponseImplementation < NucleusCore::SimpleObject
    def initialize(format, attrs={})
      default_attrs = { content: nil, headers: nil, status: nil, location: nil, format: nil }
      format_attrs = NucleusCore.configuration.response_formats[format] || {}
      status = status_code(attrs[:status])

      super(
        default_attrs
          .merge!(format_attrs)
          .merge!(attrs)
          .merge!(format: format, status: status)
      )
    end

    private

    def status_code(status=nil)
      status = Utils.status_code(status)

      status.zero? ? 200 : status
    end
  end
end
