require "test_helper"
require "nucleus/response_adapter"

def format_to_view_map
  {
    json: Nucleus::JsonResponse,
    xml: Nucleus::XmlResponse,
    text: Nucleus::TextResponse,
    pdf: Nucleus::PdfResponse,
    csv: Nucleus::CsvResponse
  }
end

describe Nucleus::Responder do
  describe "success" do
    it "returns expected response entity" do
      response = TestController.new.index

      assert(response.is_a?(Nucleus::JsonResponse))
    end

    format_to_view_map.each do |request_format, view_class|
      describe "with #{request_format} request" do
        subject do
          controller = TestController.new(request_format: request_format)
          controller.index
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
        controller = TestController.new(params: { total: {} })
        controller.index
      end

      it "returns expected response entity" do
        response = subject

        assert(response.is_a?(Nucleus::JsonResponse))
        assert_equal(500, response.status)
        assert_equal(:internal_server_error, response.content["status"])
        assert_match("undefined method `+' for {}:Hash", response.content["message"])
        assert_empty(response.content["errors"])
      end
    end

    describe "when the operation fails" do
      subject do
        # A total > 20 forces a context error implemented inside SimpleWorkflow
        controller = TestController.new(params: { total: 21 })
        controller.show
      end

      it "returns expected response entity" do
        response = subject

        expected_response = {
          "status"  => :unprocessable_entity,
          "message" => "total has reached max",
          "errors"  => []
        }
        assert(response.is_a?(Nucleus::JsonResponse))
        assert_equal(expected_response, response.content)
        assert_equal(422, response.status)
      end
    end
  end
end
