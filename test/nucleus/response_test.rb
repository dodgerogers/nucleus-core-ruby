require "test_helper"

describe Nucleus::ResponseAdapter do
  subject { Nucleus::ResponseAdapter.new }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_respond_to(resp, :content)
      assert_respond_to(resp, :headers)
      assert_respond_to(resp, :status)
      assert_respond_to(resp, :location)
    end
  end
end
