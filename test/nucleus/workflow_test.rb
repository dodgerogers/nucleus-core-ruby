require "test_helper"

describe Nucleus::Workflow do
  describe "#call" do
    before do
      @total = 0
      @process = nil
      @signal = nil
    end

    subject { SimpleWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

    describe "with nil context, and signal" do
      it "returns the expected context, and process state" do
        context, process = subject

        assert_predicate(context, :success?)
        assert_equal(3, context.total)
        assert_equal(:stopped, process.state)
      end
    end

    describe "with a valid signal" do
      before do
        @process = Nucleus::Workflow::Process.new(:started)
        @signal = :stop
      end

      it "returns the expected context, and process state" do
        context, process = subject

        assert_predicate(context, :success?)
        assert_equal(2, context.total)
        assert_equal(:stopped, process.state)
      end
    end

    describe "with invalid signal" do
      before do
        @signal = :invalid
      end

      it "returns the expected failed context, and process state" do
        context, process = subject

        refute_predicate(context, :success?)
        assert_match(/invalid signal: #{@signal}/, context.message)
        assert_equal(:initial, process.state)
      end
    end

    describe "when a custom signal condition is satisfied" do
      before do
        @total = 11
      end

      it "returns the expected context, and process state" do
        context, process = subject

        assert_predicate(context, :success?)
        assert_equal(14, context.total)
        assert_equal(:stopped, process.state)
        assert_equal(%i[started paused stopped], process.visited)
      end
    end

    describe "when the operation fails" do
      subject { FailingWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

      it "fails the context" do
        context, process = subject

        refute_predicate(context, :success?)
        assert_equal("worfkflow error!", context.message)
        assert_equal(:initial, process.state)
      end
    end

    describe "unhandled exception" do
      subject do
        FailingWorkflow.call(process: nil, signal: :raise_exception)
      end

      it "fails the context" do
        context, process = subject

        refute_predicate(context, :success?)
        assert_equal("Unhandled exception FailingWorkflow: not found", context.message)
        assert(context.exception.is_a?(Nucleus::NotFound))
        assert_equal("not found", context.exception.message)
        assert_equal(:initial, process.state)
      end
    end
  end

  describe "#rollback" do
    before do
      @args = { process: nil, signal: nil, context: { total: 0 } }
    end

    it "reverts specified side effects" do
      context, process = RollbackWorkflow.call(context: @args)

      assert_predicate(context, :success?)
      assert_equal(3, context.total)
      assert_equal(:stopped, process.state)
      assert_equal(%i[started running sprinting stopped], process.visited)

      RollbackWorkflow.rollback(process: process, context: context)

      assert_equal(0, context.total)
    end
  end
end
