require "test_helper"
require "ostruct"

describe Nucleus::Policy do
  before do
    @user = OpenStruct.new(id: 1)
    @record = OpenStruct.new(id: 1)
    @policy = TestPolicy.new(@user, @record)
  end

  describe "#enforce!" do
    describe "when policy is satisfied" do
      it "returns true" do
        assert(@policy.enforce!(:can_read?, :can_write?))
      end
    end

    describe "when policy is NOT satisfied" do
      it "returns true" do
        exception = assert_raises(Nucleus::NotAuthorized) { @policy.enforce!(:owner?) }
        assert_equal "You do not have access to: owner?", exception.message
      end
    end
  end
end
