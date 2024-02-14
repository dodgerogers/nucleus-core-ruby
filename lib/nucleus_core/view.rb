require "nucleus_core/simple_object"
require "nucleus_core/view_response_implementation"

module NucleusCore
  class View < NucleusCore::SimpleObject
    class Response < NucleusCore::ViewResponseImplementation; end

    def json_response
      NucleusCore::View::Response.new(:json, content: to_h, status: :ok)
    end
  end
end
