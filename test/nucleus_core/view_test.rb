require "test_helper"

describe NucleusCore::View do
  subject { NucleusCore::View.new(property: "value") }

  describe "#initialize" do
    it "is a subclass of SimpleObject" do
      assert_equal(NucleusCore::SimpleObject, NucleusCore::View.superclass)
    end
  end

  it "implements `json_response`" do
    response = subject.json_response

    assert_equal(:json, response.format)
    assert_equal(200, response.status)
  end
end
