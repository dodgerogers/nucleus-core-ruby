require "test_helper"

describe NucleusCore::Aggregate do
  describe "#initialize" do
    it "is a subclass of BasicObject" do
      assert_equal(NucleusCore::Aggregate.superclass, NucleusCore::BasicObject)
    end
  end
end
