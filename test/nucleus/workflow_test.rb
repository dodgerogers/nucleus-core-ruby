require "test_helper"

class WorkflowTest < Minitest::Test
  def setup
    @total = 0
    @process = nil
    @signal = nil
  end

  def subject
    SimpleWorkflow.call(process: @process, signal: @signal, context: { total: @total })
  end

  def test_simple_call
    context, process = subject

    assert_predicate(context, :success?)
    assert_equal(3, context.total)
    assert_equal(:stopped, process.state)
  end

  def test_non_starting_signal
    @process = Nucleus::Workflow::Process.new(:started)
    @signal = :stop

    context, process = subject

    assert_predicate(context, :success?)
    assert_equal(2, context.total)
    assert_equal(:stopped, process.state)
  end

  def test_determine_signal
    @total = 11

    context, process = subject

    assert_predicate(context, :success?)
    assert_equal(14, context.total)
    assert_equal(:stopped, process.state)
    assert_equal(%i[started paused stopped], process.visited)
  end

  def test_invalid_signal
    @signal = :invalid

    context, process = subject

    refute_predicate(context, :success?)
    assert_match(/invalid signal: #{@signal}/, context.message)
    assert_equal(:initial, process.state)
  end

  def test_operation_failing
    args = { process: @process, signal: @signal, context: { total: @total } }
    context, process = FailingWorkflow.call(args)

    refute_predicate(context, :success?)
    assert_equal("worfkflow error!", context.message)
    assert_equal(:initial, process.state)
  end

  def test_rollback
    args = { process: @process, signal: @signal, context: { total: @total } }
    context, process = RollbackWorkflow.call(args)

    assert_predicate(context, :success?)
    assert_equal(3, context.total)
    assert_equal(:stopped, process.state)
    assert_equal(%i[started running sprinting stopped], process.visited)

    RollbackWorkflow.rollback(process: process, context: context)

    assert_equal(0, context.total)
  end
end
