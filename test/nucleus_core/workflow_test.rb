require "test_helper"

describe NucleusCore::Workflow do
  describe "#call" do
    before do
      @total = 0
      @process = nil
      @signal = nil
    end

    subject do
      lambda { |&block|
        SimpleWorkflow.call(process: @process, signal: @signal, context: { total: @total }, &block)
      }
    end

    describe "with nil context, and signal" do
      it "returns the expected context, and process state" do
        context = subject.call do |process|
          assert_equal(:stopped, process.state)
        end

        assert_predicate(context, :success?)
        assert_equal(3, context.total)
      end
    end

    describe "with a valid signal" do
      before do
        @process = NucleusCore::Workflow::Process.new(:started)
        @signal = :stop
      end

      it "returns the expected context, and process state" do
        context = subject.call do |process|
          assert_equal(:stopped, process.state)
        end

        assert_predicate(context, :success?)
        assert_equal(2, context.total)
      end
    end

    describe "with invalid signal" do
      before do
        @signal = :invalid
      end

      it "returns the expected failed context, and process state" do
        context = subject.call do |process|
          assert_equal(:initial, process.state)
        end

        refute_predicate(context, :success?)
        assert_match(/invalid signal: #{@signal}/, context.message)
      end
    end

    describe "when a custom signal condition is satisfied" do
      before do
        @total = 11
      end

      it "returns the expected context, and process state" do
        context = subject.call do |process|
          assert_equal(:stopped, process.state)
          assert_equal(%i[started paused stopped], process.visited)
        end

        assert_predicate(context, :success?)
        assert_equal(14, context.total)
      end
    end

    describe "when the operation fails" do
      subject do
        lambda { |&block|
          FailingWorkflow.call(
            process: @process,
            signal: @signal,
            context: { total: @total },
            &block
          )
        }
      end

      it "fails the context" do
        context = subject.call do |process|
          assert_equal(:initial, process.state)
        end

        refute_predicate(context, :success?)
        assert_match(/workflow error!/, context.message)
      end
    end

    describe "when persisting the workflow process" do
      # - Replaces `SimpleWorkflow.handle_execution_step` with a stub that persists the process.
      # - Calls `SimpleWorkflow.call` with test parameters (`@process`, `@signal`, `@total`).
      # - Allows passing a block to `SimpleWorkflow.call`, enabling further customization in individual tests.
      # - Ensures that the stubbed method is only applied within the test execution.
      subject do
        lambda { |&block|
          stub = ->(process, *_args) { TestRepository.persist_process(process) }
          SimpleWorkflow.stub(:handle_execution_step, stub) do
            SimpleWorkflow.call(
              process: @process,
              signal: @signal,
              context: { total: @total },
              &block
            )
          end
        }
      end

      describe "and it succeeds" do
        it "returns the expected context" do
          context = subject.call do |process|
            assert_equal(:stopped, process.state)
          end

          assert_predicate(context, :success?)
        end
      end

      describe "and it fails" do
        # - Replaces `SimpleWorkflow.handle_execution_step` with a stub that fails to persist the process.
        # - Calls `SimpleWorkflow.call` with test parameters (`@process`, `@signal`, `@total`).
        # - Allows passing a block to `SimpleWorkflow.call`, enabling further customization in individual tests.
        # - Ensures that the stubbed method is only applied within the test execution.
        subject do
          lambda { |&block|
            stub = ->(process, *_args) { TestRepository.failing_persist_process(process) }
            FailingWorkflow.stub(:handle_execution_step, stub) do
              FailingWorkflow.call(
                process: @process,
                signal: @signal,
                context: { total: @total },
                &block
              )
            end
          }
        end

        it "returns the expected context" do
          context = subject.call do |process|
            assert_equal(:initial, process.state)
          end

          refute_predicate(context, :success?)
        end
      end
    end

    describe "unhandled exception" do
      subject do
        ->(&block) { FailingWorkflow.call(process: nil, signal: :raise_exception, &block) }
      end

      it "fails the context" do
        context = subject.call do |process|
          assert_equal(:initial, process.state)
        end

        refute_predicate(context, :success?)
        assert_match(/Unhandled exception FailingWorkflow: not found/, context.message)
        assert(context.exception.is_a?(NucleusCore::NotFound))
        assert_match(/not found/, context.exception.message)
      end
    end

    describe "chain of command execution" do
      subject do
        ->(&block) { ChainOfCommandWorkflow.call(context: {}, &block) }
      end

      it "fails the context" do
        context = subject.call do |process|
          assert_equal(:four, process.state)
        end

        refute_predicate(context, :success?)
      end
    end
  end

  describe "#rollback" do
    before do
      @args = { process: nil, signal: nil, context: { total: 0 } }
    end

    it "reverts specified side effects" do
      process = nil
      context = RollbackWorkflow.call(context: @args) do |p, _graph, _context|
        process = p
        assert_equal(:stopped, process.state)
        assert_equal(%i[started running sprinting stopped], process.visited)
      end

      assert_predicate(context, :success?)
      assert_equal(3, context.total)

      RollbackWorkflow.rollback(process: process, context: context)

      assert_equal(0, context.total)
    end
  end
end
