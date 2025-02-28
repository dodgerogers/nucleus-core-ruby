require "test_helper"

describe NucleusCore::ResponseAdapter do
  before do
    @entity = NucleusCore::View::Response.new(:json, content: { key: "value" })
  end

  describe "#call" do
    subject { NucleusCore::ResponseAdapter.new.call(@entity) }

    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { subject }
    end
  end

  describe "self.call" do
    subject { NucleusCore::ResponseAdapter.call(@entity) }

    it "raises NotImplementedError" do
      assert_raises(NotImplementedError) { subject }
    end
  end
end
