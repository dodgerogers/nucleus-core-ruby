require "test_helper"
require "nucleus_core/response_adapter"

def format_to_view_map
  {
    json: NucleusCore::JsonResponse,
    xml: NucleusCore::XmlResponse,
    text: NucleusCore::TextResponse,
    pdf: NucleusCore::PdfResponse,
    csv: NucleusCore::CsvResponse
  }
end

describe NucleusCore::Responder do
  describe "success" do
    it "returns expected response entity" do
      response = TestController.index

      assert(response.is_a?(NucleusCore::JsonResponse))
    end

    format_to_view_map.each do |request_format, view_class|
      describe "with #{request_format} request" do
        subject do
          TestController.index(request_format: request_format)
        end

        it "returns expected response entity" do
          response = subject

          assert(response.is_a?(view_class))
        end
      end
    end
  end

  describe "failure" do
    describe "when an exception is raised" do
      subject do
        # {} will force a NoMethodError when we try and perform addition
        TestController.index(params: { total: {} })
      end

      it "returns expected response entity" do
        response = subject

        assert(response.is_a?(NucleusCore::JsonResponse))
        assert_equal(500, response.status)
        assert_equal(:internal_server_error, response.content["status"])
        assert_match("undefined method `+' for {}:Hash", response.content["message"])
        assert_empty(response.content["errors"])
      end
    end

    describe "when the operation fails" do
      subject do
        # A total > 20 forces a context error implemented inside SimpleWorkflow
        TestController.show(params: { total: 21 })
      end

      it "returns expected response entity" do
        response = subject

        expected_response = {
          "status"  => :unprocessable_entity,
          "message" => "total has reached max",
          "errors"  => []
        }
        assert(response.is_a?(NucleusCore::JsonResponse))
        assert_equal(expected_response, response.content)
        assert_equal(422, response.status)
      end
    end
  end
end
