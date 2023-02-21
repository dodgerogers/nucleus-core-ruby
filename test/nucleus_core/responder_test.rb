require "test_helper"

describe NucleusCore::Responder do
  describe "success" do
    subject { TestController.new.index }

    it "returns expected response entity" do
      response = subject

      assert(response.is_a?(NucleusCore::JsonResponse))
    end

    {
      json: NucleusCore::JsonResponse,
      xml: NucleusCore::XmlResponse,
      text: NucleusCore::TextResponse,
      pdf: NucleusCore::PdfResponse,
      csv: NucleusCore::CsvResponse
    }.each do |request_format, view_class|
      describe "when #{request_format} request" do
        subject { TestController.new.index(format: request_format) }

        it "returns expected response entity" do
          response = subject

          assert(response.is_a?(view_class))
        end
      end
    end

    describe "when a response object is returned" do
      subject { TestController.new.update(format: :json) }

      it "renders response in the returned format irrespective to the request format" do
        response = subject

        assert(response.is_a?(NucleusCore::CsvResponse))
      end
    end
  end

  describe "failure" do
    describe "when an exception is raised" do
      subject { TestController.new.show(params: { total: :nan }) }

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
      subject { TestController.new.show(params: { total: 21 }) }

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
