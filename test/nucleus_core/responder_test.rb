require "test_helper"

describe NucleusCore::Responder do
  describe "success" do
    subject { TestController.new.workflow }

    it "returns expected response entity" do
      response = subject

      assert_equal(:json, response.format)
      assert_equal({ total: 8, state: :stopped }, response.content)
      assert_nil(response.headers)
      assert_equal(200, response.status)
      assert_nil(response.location)
      assert_equal("application/json", response.type)
    end

    %i[json xml text pdf csv].each do |request_format|
      describe "when #{request_format} request" do
        subject { TestController.new.workflow(format: request_format) }

        it "returns expected response entity" do
          response = subject

          assert_equal(request_format, response.format)
        end
      end
    end

    describe "when a response object is returned" do
      subject { TestController.new.csv(format: :json) }

      it "renders response in the returned format irrespective to the request format" do
        response = subject

        assert_equal(:csv, response.format)
      end
    end

    describe "when an successful Operation::Context is returned" do
      subject { TestController.new.successful_operation_context(format: :json) }

      it "renders response in the returned format irrespective to the request format" do
        response = subject

        assert_equal(:nothing, response.format)
        assert_nil(response.content)
      end
    end

    describe "when a failed Operation::Context is returned" do
      subject { TestController.new.failed_operation_context(format: :json) }

      it "renders expected" do
        response = subject

        assert_equal(:json, response.format)
        assert_equal(500, response.status)
        assert_equal(:internal_server_error, response.content[:status])
        assert_match(/something went wrong/, response.content[:message])
      end
    end

    describe "when nil is returned" do
      subject { TestController.new.nothing }

      it "renders expected no content status" do
        response = subject

        assert_equal(:nothing, response.format)
      end

      describe "with custom headers" do
        subject { TestController.new.nothing_extended }

        it "renders expected no content status" do
          response = subject

          assert_equal(:nothing, response.format)
          assert_equal({ "nothing" => "header" }, response.headers)
        end
      end
    end

    describe "when format is not given" do
      subject { TestController.new.no_format }

      it "renders expected default content type" do
        response = subject

        assert_equal(:json, response.format)
      end
    end

    describe "when view does not implement the requested html format" do
      subject { TestController.new.unsupported_html_format_requested }

      it "renders error in `default_response_format`" do
        response = subject

        assert_equal(:json, response.format)
        assert_equal(NucleusCore.configuration.default_response_format, response.format)
        assert_equal(:bad_request, response.content[:status])
        assert_equal("`html` is not supported", response.content[:message])
      end

      describe "and `default_response_format` is not defined" do
        subject { TestController.new.unsupported_html_format_requested }

        before do
          @default_response_format = NucleusCore.configuration.default_response_format
          NucleusCore.configuration.default_response_format = nil
        end

        after do
          NucleusCore.configuration.default_response_format = @default_response_format
        end

        it "renders error in fallback `json` content type" do
          response = subject

          assert_equal(:json, response.format)
          assert_equal(:bad_request, response.content[:status])
          assert_equal("`html` is not supported", response.content[:message])
        end
      end
    end
  end

  describe "failure" do
    describe "when an exception is raised" do
      subject { TestController.new.operation(params: { total: :nan }) }

      it "returns expected response entity" do
        response = subject

        assert_equal(:json, response.format)
        assert_equal(500, response.status)
        assert_equal(:internal_server_error, response.content[:status])
        assert_match("comparison of Symbol with 20 failed", response.content[:message])
        assert_empty(response.content[:errors])
      end
    end

    describe "when the operation fails" do
      subject { TestController.new.operation(params: { total: 21 }) }

      it "returns expected response entity" do
        response = subject

        expected_response = {
          status: :unprocessable_entity,
          message: "total has reached max",
          errors: []
        }
        assert_equal(:json, response.format)
        assert_equal(expected_response, response.content)
        assert_equal(422, response.status)
      end
    end
  end
end
