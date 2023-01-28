require "test_helper"

describe Nucleus::Aggregate do
  describe "#initialize" do
    it "is a subclass of BasicObject" do
      assert_equal(Nucleus::Aggregate.superclass, Nucleus::BasicObject)
    end
  end
end
