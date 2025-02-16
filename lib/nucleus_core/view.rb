require "nucleus_core/entity"
require "nucleus_core/view_response_implementation"

module NucleusCore
  class View < NucleusCore::Entity
    class Response < NucleusCore::ViewResponseImplementation; end

    def json
      NucleusCore::View::Response.new(:json, content: to_h, status: :ok)
    end
  end
end
