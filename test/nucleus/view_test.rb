require "test_helper"

describe Nucleus::View do
  describe "#initialize" do
    it "is a subclass of BasicObject" do
      assert_equal(Nucleus::View.superclass, Nucleus::BasicObject)
    end
  end
end
