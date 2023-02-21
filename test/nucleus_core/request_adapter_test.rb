require "test_helper"

describe NucleusCore::RequestAdapter do
  subject { NucleusCore::RequestAdapter.new }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_respond_to(resp, :format)
      assert_respond_to(resp, :parameters)
    end
  end
end
