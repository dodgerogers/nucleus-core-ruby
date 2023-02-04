require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::CsvResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "attachment",
      filename: attrs.fetch(:filename) { "response.csv" },
      type: "text/csv; charset=UTF-8;"
    )

    super(attrs)
  end
end
