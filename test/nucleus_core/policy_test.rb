require "test_helper"

describe NucleusCore::Policy do
  before do
    @client = Object.new
    @entity = Object.new
    @policy = TestPolicy.new(@client, @entity)
  end

  describe "#enforce!" do
    describe "when policy is satisfied" do
      it "returns true" do
        assert(@policy.enforce!(:read?, :write?))
      end
    end

    describe "when policy is NOT satisfied" do
      it "returns true" do
        exception = assert_raises(NucleusCore::NotAuthorized) do
          @policy.enforce!(:owner?)
        end

        assert_equal "You do not have access to `owner?`", exception.message
      end
    end
  end
end
