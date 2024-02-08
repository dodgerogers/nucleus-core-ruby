require "test_helper"

describe NucleusCore::View do
  subject { NucleusCore::View.new(property: "value") }

  describe "#initialize" do
    it "exposes expected attributes" do
      assert_equal("value", subject.property)
    end

    it "has expected subclass" do
      assert_equal(NucleusCore::SimpleObject, NucleusCore::View.superclass)
    end
  end

  it "implements `json_response`" do
    response = subject.json_response

    assert_equal(:json, response.format)
    assert_equal(200, response.status)
  end
end
