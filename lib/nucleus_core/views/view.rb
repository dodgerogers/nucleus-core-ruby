class NucleusCore::View < NucleusCore::BasicObject
  def json_response
    NucleusCore::JsonResponse.new(content: to_h, status: :ok)
  end
end
