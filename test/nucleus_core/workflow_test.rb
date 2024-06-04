require "test_helper"

describe NucleusCore::Workflow do
  describe "#call" do
    before do
      @total = 0
      @process = nil
      @signal = nil
    end

    subject { SimpleWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

    describe "with nil context, and signal" do
      it "returns the expected context, and process state" do
        manager = subject
        context = manager.context
        process = manager.process

        assert_predicate(context, :success?)
        assert_equal(3, context.total)
        assert_equal(:stopped, process.state)
      end
    end

    describe "with a valid signal" do
      before do
        @process = NucleusCore::Workflow::Process.new(:started)
        @signal = :stop
      end

      it "returns the expected context, and process state" do
        manager = subject
        context = manager.context
        process = manager.process

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
        manager = subject
        context = manager.context
        process = manager.process

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
        manager = subject
        context = manager.context
        process = manager.process

        assert_predicate(context, :success?)
        assert_equal(14, context.total)
        assert_equal(:stopped, process.state)
        assert_equal(%i[started paused stopped], process.visited)
      end
    end

    describe "when the operation fails" do
      subject { FailingWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

      it "fails the context" do
        manager = subject
        context = manager.context
        process = manager.process

        refute_predicate(context, :success?)
        assert_match(/workflow error!/, context.message)
        assert_equal(:initial, process.state)
      end
    end

    describe "when persisting the workflow process" do
      subject do
        FailingWorkflow.call(
          process: @process,
          signal: @signal,
          context: { total: @total }
        ) do |process, _graph, _context|
          TestRepository.persist_process(process)
        end
      end

      describe "and it succeeds" do
        it "returns the expected context" do
          manager = subject
          context = manager.context
          process = manager.process

          assert_predicate(context, :success?)
          assert_equal(:stopped, process.state)
        end
      end

      describe "and it fails" do
        subject do
          FailingWorkflow.call(
            process: @process,
            signal: @signal,
            context: { total: @total }
          ) do |process, _graph, _context|
            TestRepository.failing_persist_process(process)
          end
        end

        it "returns the expected context" do
          manager = subject
          context = manager.context
          process = manager.process

          assert_predicate(context, :success?)
          assert_equal(:stopped, process.state)
        end
      end
    end

    describe "unhandled exception" do
      subject do
        FailingWorkflow.call(process: nil, signal: :raise_exception)
      end

      it "fails the context" do
        manager = subject
        context = manager.context
        process = manager.process

        refute_predicate(context, :success?)
        assert_match(/Unhandled exception FailingWorkflow: not found/, context.message)
        assert(context.exception.is_a?(NucleusCore::NotFound))
        assert_match(/not found/, context.exception.message)
        assert_equal(:initial, process.state)
      end
    end
  end

  describe "#rollback" do
    before do
      @args = { process: nil, signal: nil, context: { total: 0 } }
    end

    it "reverts specified side effects" do
      manager = RollbackWorkflow.call(context: @args)
      context = manager.context
      process = manager.process

      assert_predicate(context, :success?)
      assert_equal(3, context.total)
      assert_equal(:stopped, process.state)
      assert_equal(%i[started running sprinting stopped], process.visited)

      RollbackWorkflow.rollback(process: process, context: context)

      assert_equal(0, context.total)
    end
  end
end
