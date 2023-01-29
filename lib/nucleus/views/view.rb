class Nucleus::View < Nucleus::BasicObject
  def json_response
    Nucleus::JsonResponse.new(content: to_h, status: :ok)
  end
end
