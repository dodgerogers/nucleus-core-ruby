require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::TextResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/text")

    super(attrs)
  end
end
