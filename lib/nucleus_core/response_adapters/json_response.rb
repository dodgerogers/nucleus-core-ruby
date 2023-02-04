require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::JsonResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/json")

    super(attrs)
  end
end
