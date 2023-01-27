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

    assert(context.success?)
    assert_equal(3, context.total)
    assert_equal(:stopped, process.state)
  end

  def test_non_starting_signal
    @process = Nucleus::Workflow::Process.new(:started)
    @signal = :stop

    context, process = subject

    assert(context.success?)
    assert_equal(2, context.total)
    assert_equal(:stopped, process.state)
  end

  def test_determine_signal
    @total = 10

    context, process = subject

    assert(context.success?)
    assert_equal(13, context.total)
    assert_equal(:stopped, process.state)
    assert(process.visited.include?(:paused))
  end

  def test_invalid_signal
    @signal = :invalid

    context, process = subject

    refute(context.success?)
    assert_match(/invalid signal: #{@signal}/, context.message)
    assert_equal(:initial, process.state)
  end

  def test_failing_context
    context, process = FailingWorkflow.call(process: @process, signal: @signal, context: { total: @total })

    refute(context.success?)
    assert_equal("worfkflow error!", context.message)
    assert_equal(:initial, process.state)
  end
end
