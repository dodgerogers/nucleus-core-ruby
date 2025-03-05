require "test_helper"

describe NucleusCore::Workflow do
  describe "#call" do
    before do
      @total = 0
      @initial_state = SimpleWorkflow::INITIAL_STATE
      @process = NucleusCore::Workflow::Process.new(@initial_state)
      @signal = nil
    end

    subject { SimpleWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

    describe "with nil context, and signal" do
      it "returns the expected context, and process state" do
        assert_predicate(subject, :success?)
        assert_equal(3, subject.total)
        assert_equal(:stopped, @process.state)
      end
    end

    describe "with a valid signal" do
      before do
        @process = NucleusCore::Workflow::Process.new(:started)
        @signal = :stop
      end

      it "returns the expected context, and process state" do
        assert_predicate(subject, :success?)
        assert_equal(2, subject.total)
        assert_equal(:stopped, @process.state)
      end
    end

    describe "comprised of nested graphs" do
      subject { WorkflowCallingWorkflow.call(process: @process, signal: @signal, context: { total: @total }) }

      it "returns the expected context, and process state" do
        assert_predicate(subject, :success?)
        assert_equal(6, subject.total)
        assert_equal(:finished, @process.state)
      end
    end

    describe "with invalid signal" do
      before do
        @signal = :invalid
      end

      it "returns the expected failed context, and process state" do
        refute_predicate(subject, :success?)
        assert_match(/invalid signal: #{@signal}/, subject.message)
        assert_equal(:initial, @process.state)
      end
    end

    describe "when a custom signal condition is satisfied" do
      before do
        @total = 11
      end

      it "returns the expected context, and process state" do
        assert_predicate(subject, :success?)
        assert_equal(14, subject.total)
        assert_equal(:stopped, @process.state)
        assert_equal(%i[started paused stopped], @process.visited)
      end
    end

    describe "when the operation fails" do
      subject do
        FailingWorkflow.call(
          process: @process,
          signal: @signal,
          context: { total: @total }
        )
      end

      it "fails the context" do
        refute_predicate(subject, :success?)
        assert_match(/workflow error!/, subject.message)
        assert_equal(:initial, @process.state)
      end
    end

    describe "when persisting the workflow process" do
      # - Replaces `SimpleWorkflow.handle_execution_step` with a stub that persists the process.
      # - Calls `SimpleWorkflow.call` with test parameters (`@process`, `@signal`, `@total`).
      # - Ensures that the stubbed method is only applied within the test execution.
      subject do
        stub = ->(process, *_args) { TestRepository.persist_process(process) }
        SimpleWorkflow.stub(:handle_execution_step, stub) do
          SimpleWorkflow.call(
            process: @process,
            signal: @signal,
            context: { total: @total }
          )
        end
      end

      describe "and it succeeds" do
        it "returns the expected context" do
          assert_predicate(subject, :success?)
          assert_equal(:stopped, @process.state)
        end
      end

      describe "and it fails" do
        # - Replaces `SimpleWorkflow.handle_execution_step` with a stub that fails to persist the process.
        # - Calls `SimpleWorkflow.call` with test parameters (`@process`, `@signal`, `@total`).
        # - Ensures that the stubbed method is only applied within the test execution.
        subject do
          stub = ->(process, *_args) { TestRepository.failing_persist_process(process) }
          SimpleWorkflow.stub(:handle_execution_step, stub) do
            SimpleWorkflow.call(
              process: @process,
              signal: @signal,
              context: { total: @total }
            )
          end
        end

        it "returns the expected context" do
          refute_predicate(subject, :success?)
          assert_match(/unhandled exception SimpleWorkflow: failing_persist_process failed/i, subject.message)
          assert_equal(:started, @process.state)
        end
      end
    end

    describe "unhandled exception" do
      subject { FailingWorkflow.call(process: @process, signal: :raise_exception) }

      it "fails the context" do
        refute_predicate(subject, :success?)
        assert_match(/Unhandled exception FailingWorkflow: not found/, subject.message)
        assert_kind_of(NucleusCore::NotFound, subject.exception)
        assert_match(/not found/, subject.exception.message)
        assert_equal(:initial, @process.state)
      end
    end

    describe "chain of command execution" do
      subject { ChainOfCommandWorkflow.call(context: {}, process: @process) }

      it "fails the context" do
        refute_predicate(subject, :success?)
        assert_equal(:four, @process.state)
      end
    end
  end

  describe "#rollback" do
    before do
      @initial_state = SimpleWorkflow::INITIAL_STATE
      @process = NucleusCore::Workflow::Process.new(@initial_state)
    end

    it "reverts specified side effects" do
      context = RollbackWorkflow.call(process: @process, signal: nil, context: { total: 0 })
      assert_predicate(context, :success?)
      assert_equal(3, context.total)
      assert_equal(:stopped, @process.state)
      assert_equal(%i[started running sprinting stopped], @process.visited)

      RollbackWorkflow.rollback(process: @process, context: context)

      assert_equal(0, context.total)
    end
  end
end
