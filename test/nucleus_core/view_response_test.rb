require "test_helper"

describe NucleusCore::View::Response do
  subject { NucleusCore::View::Response.new(:csv, { content: "content" }) }

  describe "initialize" do
    it "sets expected properties" do
      resp = subject

      assert_equal("content", resp.content)
      assert_nil(resp.headers)
      assert_equal(200, resp.status)
      assert_nil(resp.location)
      assert_equal(:csv, resp.format)
    end
  end
end
