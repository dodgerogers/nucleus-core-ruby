require "test_helper"

describe NucleusCore::View do
  describe "#initialize" do
    it "is a subclass of SimpleObject" do
      assert_equal(NucleusCore::View.superclass, NucleusCore::SimpleObject)
    end
  end
end
