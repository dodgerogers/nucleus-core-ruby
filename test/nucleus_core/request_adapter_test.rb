require "test_helper"

describe NucleusCore::RequestAdapter do
  before do
    @request = { parameters: { key: "value" } }
  end

  subject { NucleusCore::RequestAdapter.new(@request) }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_respond_to(resp, :format)
      assert_respond_to(resp, :parameters)
    end
  end
end
