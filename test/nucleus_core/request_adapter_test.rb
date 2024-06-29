require "test_helper"

describe NucleusCore::RequestAdapter do
  before do
    @request = { parameters: { key: "value" } }
  end

  subject { NucleusCore::RequestAdapter.new(@request) }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_equal(NucleusCore.configuration.default_response_format, resp.format)
      assert_equal(@request[:parameters], resp.parameters)
    end
  end
end
