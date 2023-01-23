require "test_helper"

class SimpleWorkflow < Nucleus::Workflow
  def define
    register_node(
      state: :initial,
      signals: { continue: :started }
    )
    register_node(
      state: :started,
      operation: lambda {|context| context.total += 1 },
      determine_signal: lambda {|context| context.total > 10 ? :pause : :stop },
      signals: { pause: :paused, stop: :stopped }
    )
    register_node(
      state: :paused,
      operation: lambda {|_| },
      signals: { continue: :stopped }
    )
    register_node(
      state: :stopped,
      operation: lambda {|context| context.total += 2 },
      determine_signal: lambda {|_| :wait }
    )
  end
end


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

    assert_match(/invalid signal: #{@signal}/, context.message)
    assert(context.exception.is_a?(ArgumentError))
    assert_equal(:initial, process.state)
  end
end
