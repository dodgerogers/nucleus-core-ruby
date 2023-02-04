require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::PdfResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "inline",
      filename: attrs.fetch(:filename) { "response.pdf" },
      type: "application/pdf"
    )

    super(attrs)
  end
end
