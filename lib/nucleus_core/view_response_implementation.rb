module NucleusCore
  class ViewResponseImplementation < NucleusCore::SimpleObject
    FORMAT_ATTRIBUTES = {
      csv: { disposition: "attachment", type: "text/csv; charset=UTF-8;", filename: "response.csv" },
      pdf: { disposition: "inline", type: "application/pdf", filename: "response.pdf" },
      json: { type: "application/json", format: :json },
      xml: { type: "application/xml", format: :xml },
      html: { type: "text/html", format: :html },
      text: { type: "text/plain", format: :text },
      nothing: { content: nil, type: "text/html; charset=utf-8", format: :nothing }
    }.freeze

    def initialize(format, attrs={})
      default_attrs = { content: nil, headers: nil, status: nil, location: nil, format: nil }
      format_attrs = FORMAT_ATTRIBUTES[format]
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
