require "nucleus_core/simple_object"

module NucleusCore
  class ViewResponseImplementation < NucleusCore::SimpleObject
    def initialize(res_format=nil, attrs={})
      res_format ||= NucleusCore.configuration.default_response_format
      attrs_method = "#{res_format}_attributes"
      res_format_attrs = send(attrs_method, attrs)

      attributes = default_attrs
        .merge(res_format_attrs)
        .merge(attrs)
        .merge(format: res_format, status: status_code(attrs[:status]))

      super(attributes)
    end

    private

    def default_attrs
      { content: nil, headers: nil, status: nil, location: nil, format: nil }
    end

    def status_code(status=nil)
      status = Utils.status_code(status)
      default_status = 200

      status.zero? ? default_status : status
    end

    def csv_attributes(attrs={})
      {
        disposition: "attachment",
        filename: attrs.fetch(:filename) { "response.csv" },
        type: "text/csv; charset=UTF-8;",
        format: :csv
      }
    end

    def pdf_attributes(attrs={})
      {
        disposition: "inline",
        filename: attrs.fetch(:filename) { "response.pdf" },
        type: "application/pdf",
        format: :pdf
      }
    end

    def json_attributes(_attrs={})
      { type: "application/json", format: :json }
    end

    def xml_attributes(_attrs={})
      { type: "application/xml", format: :xml }
    end

    def html_attributes(_attrs={})
      { type: "text/html", format: :html }
    end

    def text_attributes(_attrs={})
      { type: "text/plain", format: :text }
    end

    def nothing_attributes(_attrs={})
      { content: nil, type: "text/html; charset=utf-8" }
    end
  end
end
