require "test_helper"
require "ostruct"

class TestOperation < Nucleus::Operation
  def call
    context.fail!("total has reached max", exception: StandardError.new) if context.total >= 20

    context.total += 1
  end

  def rollback
    context.total -= 1
  end
end

class OperationTest < Minitest::Test
  def setup
    @total = 10
  end

  def subject
    TestOperation.call(total: @total)
  end

  def test_call_with_valid_parameters
    context = subject

    assert_predicate(context, :success?)
    assert_equal(11, context.total)
  end

  def test_call_with_failure
    @total = 20
    context = subject

    refute_predicate(context, :success?)
    assert_equal("total has reached max", context.message)
    assert_equal(StandardError, context.exception.class)
  end

  def test_rollback
    context = Nucleus::Operation::Context.new(total: 5)
    context = TestOperation.rollback(context)

    assert_equal(4, context.total)
  end
end
