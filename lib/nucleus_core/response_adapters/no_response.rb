require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::NoResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(content: nil, type: "text/html; charset=utf-8")

    super(attrs)
  end
end
