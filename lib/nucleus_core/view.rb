require "nucleus_core/simple_object"
require "nucleus_core/view_response"

module NucleusCore
  class View < NucleusCore::SimpleObject
    class Response < NucleusCore::ViewResponse; end

    def json_response
      NucleusCore::View::Response.new(:json, content: to_h, status: :ok)
    end
  end
end
