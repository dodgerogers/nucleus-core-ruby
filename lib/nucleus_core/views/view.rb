require "nucleus_core/response_adapter"

class NucleusCore::View < NucleusCore::SimpleObject
  def json_response
    NucleusCore::ResponseAdapter.new(:json, content: to_h, status: :ok)
  end
end
