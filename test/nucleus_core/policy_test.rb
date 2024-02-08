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
        policy_method = :read?
        policy_method_with_args = [:even?, 2, 4]
        assert(@policy.enforce!(policy_method, policy_method_with_args))
      end
    end

    describe "when policy is NOT satisfied" do
      it "returns true" do
        policy_method = :read?
        policy_method_with_args = [:even?, 1, 4]
        exception = assert_raises(NucleusCore::Unauthorized) do
          assert(@policy.enforce!(policy_method, policy_method_with_args))
        end

        assert_equal "You do not have access to `even?`", exception.message
      end
    end
  end
end
