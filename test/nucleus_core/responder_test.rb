require "test_helper"

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
    subject do
      controller = TestController.new
      controller.init_responder(response_adapter: TestAdapter, request_format: :json)
      controller.index
    end

    it "returns expected response entity" do
      response = subject

      assert(response.is_a?(NucleusCore::JsonResponse))
    end

    format_to_view_map.each do |request_format, view_class|
      describe "with #{request_format} request" do
        subject do
          controller = TestController.new
          controller.init_responder(response_adapter: TestAdapter, request_format: request_format)
          controller.index
        end

        it "returns expected response entity" do
          response = subject

          assert(response.is_a?(view_class))
        end
      end
    end

    describe "when setting `response_adapter` to an instance" do
      subject do
        controller = TestController.new
        controller.init_responder(response_adapter: controller, request_format: :json)
        controller.index
      end

      it "returns expected response entity" do
        response = subject

        assert_equal("NucleusCore::JsonResponse", response)
      end

      # The injected response_adapter sets each adapter method to return the class
      # name of the returned entity
      format_to_view_map.each do |request_format, view_class|
        describe "with #{request_format} request" do
          subject do
            controller = TestController.new
            controller.init_responder(response_adapter: controller, request_format: request_format)
            controller.index
          end

          it "returns expected response entity" do
            response = subject

            assert_equal(view_class.name, response)
          end
        end
      end
    end
  end

  describe "failure" do
    describe "when an exception is raised" do
      subject do
        # {} will force a NoMethodError when we try and perform addition
        controller = TestController.new(params: { total: :wut })
        controller.init_responder(response_adapter: TestAdapter, request_format: :json)
        controller.show
      end

      it "returns expected response entity" do
        response = subject

        assert(response.is_a?(NucleusCore::JsonResponse))
        assert_equal(500, response.status)
        assert_equal(:internal_server_error, response.content[:status])
        assert_match("comparison of Symbol with 20 failed", response.content[:message])
        assert_empty(response.content[:errors])
      end
    end

    describe "when the operation fails" do
      subject do
        # A total > 20 forces a context error implemented inside SimpleWorkflow
        controller = TestController.new(params: { total: 21 })
        controller.init_responder(response_adapter: TestAdapter, request_format: :json)
        controller.show
      end

      it "returns expected response entity" do
        response = subject

        expected_response = {
          status: :unprocessable_entity,
          message: "total has reached max",
          errors: []
        }
        assert(response.is_a?(NucleusCore::JsonResponse))
        assert_equal(expected_response, response.content)
        assert_equal(422, response.status)
      end
    end
  end
end
