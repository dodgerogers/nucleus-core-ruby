require "test_helper"

module NucleusCore
  class OperationTest < Minitest::Test
    describe Operation do
      describe "Context" do
        it "initializes with given attributes" do
          context = NucleusCore::Operation::Context.new(foo: "bar")
          assert_equal("bar", context.foo)
        end

        it "is successful by default" do
          context = NucleusCore::Operation::Context.new
          assert_predicate(context, :success?)
        end

        it "can fail with a message" do
          context = NucleusCore::Operation::Context.new
          assert_raises(NucleusCore::Operation::Context::Error) do
            context.fail!("Something went wrong")
          end
          refute_predicate(context, :success?)
          assert_equal("Something went wrong", context.message)
        end
      end

      describe ".call" do
        it "executes the operation and returns the context" do
          context = DummyOperation.call(arg1: "value1", arg2: "value2")
          assert_predicate(context, :success?)
          assert_equal("Dummy", context.entity.name)
        end

        it "fails if required arguments are missing" do
          context = DummyOperation.call(arg1: "value1")
          refute_predicate(context, :success?)
          assert_equal("Missing required arguments: arg2", context.message)
        end
      end

      describe ".rollback" do
        it "executes the rollback method and returns the context" do
          context = NucleusCore::Operation::Context.new
          result_context = DummyOperation.rollback(context)
          assert(result_context.rollback_called)
        end
      end

      describe "#validate_required_args!" do
        it "fails if required arguments are missing" do
          context = DummyOperation.call(arg1: "value1")
          refute_predicate(context, :success?)
          assert_equal("Missing required arguments: arg2", context.message)
        end

        it "passes if all required arguments are present" do
          context = DummyOperation.call(arg1: "value1", arg2: "value2")
          assert_predicate(context, :success?)
        end
      end
    end
  end
end
