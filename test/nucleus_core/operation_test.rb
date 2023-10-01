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

      it "sets expected isolated context properties" do
        operation = TestOperation.new(total: @total).tap(&:call)

        assert_equal({ changes: 10 }, operation.send(:isolate))
      end
    end

    describe "when the context fails" do
      before do
        # A value greater than 20 Causes a NucleusCore::Unprocessible exception to be thrown in TestOperation
        @total = 21
      end

      it "returns a failed context with message" do
        context = subject

        refute_predicate(context, :success?)
        assert_equal("total has reached max", context.message)
        assert_instance_of(NucleusCore::Unprocessable, context.exception)
      end
    end

    describe "with missing args" do
      subject { TestOperation.call }

      it "fails the context with expected message" do
        context = subject

        refute_predicate(context, :success?)
        assert_equal("Missing required arguments: total", context.message)
      end
    end
  end

  describe "self.rollback" do
    before do
      @total = 5
      # TestOperation adds 1 to context.total
      @context = TestOperation.call(total: @total)
    end

    subject { TestOperation.rollback(@context) }

    it "reverts expected side effects" do
      assert_equal(@total + 1, @context.total)

      rollback_context = subject

      assert_equal(1, rollback_context.total)
    end
  end
end
