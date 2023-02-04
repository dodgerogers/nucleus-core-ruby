require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::XmlResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/xml")

    super(attrs)
  end
end
