require "test_helper"

describe NucleusCore::View do
  describe "#initialize" do
    it "is a subclass of BasicObject" do
      assert_equal(NucleusCore::View.superclass, NucleusCore::BasicObject)
    end
  end
end
