require "nucleus_core/response_adapters/response_adapter"

class NucleusCore::View < NucleusCore::BasicObject
  def json_response
    NucleusCore::JsonResponse.new(content: to_h, status: :ok)
  end
end
