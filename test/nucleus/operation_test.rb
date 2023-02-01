require "test_helper"

describe NucleusCore::Operation do
  describe "self.call" do
    before do
      @total = 10
    end

    subject { TestOperation.call(total: @total) }

    describe "with valid parmeters" do
      it "returns a successful context" do
        context = subject

        assert_predicate(context, :success?)
        assert_equal(11, context.total)
      end
    end

    describe "when the context fails" do
      before do
        @total = 20
      end

      it "returns a failed context with message" do
        context = subject

        refute_predicate(context, :success?)
        assert_equal("total has reached max", context.message)
        assert_equal(NucleusCore::Unprocessable, context.exception.class)
      end
    end
  end

  describe "self.rollback" do
    it "reverts expected side effects" do
      context = NucleusCore::Operation::Context.new(total: 5)
      context = TestOperation.rollback(context)

      assert_equal(4, context.total)
    end
  end
end
