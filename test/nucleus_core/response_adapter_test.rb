require "test_helper"

describe NucleusCore::ResponseAdapter do
  subject { NucleusCore::ResponseAdapter.new }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_respond_to(resp, :content)
      assert_respond_to(resp, :headers)
      assert_respond_to(resp, :status)
      assert_respond_to(resp, :location)
      assert_respond_to(resp, :format)
    end
  end
end
