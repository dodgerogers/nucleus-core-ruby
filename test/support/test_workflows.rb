class SimpleWorkflow < NucleusCore::Workflow::Graph
  def define
    start_node(continue: :started)
    add_node(
      state: :started,
      operation: lambda do |context|
        context.total ||= 0
        context.total += 1
      end,
      determine_signal: ->(context) { context.total > 10 ? :pause : :stop },
      signals: { pause: :paused, stop: :stopped }
    )
    add_node(
      state: :paused,
      signals: { continue: :stopped }
    )
    add_node(
      state: :stopped,
      operation: ->(context) { context.total += 2 },
      determine_signal: ->(_) { :wait }
    )
  end
end

class FailingWorkflow < NucleusCore::Workflow::Graph
  def define
    start_node(continue: :failed, raise_exception: :unhandled_exception)
    add_node(
      state: :failed,
      operation: ->(context) { context.fail!("workflow error!") },
      signals: { continue: :completed }
    )
    add_node(
      state: :unhandled_exception,
      operation: ->(_context) { raise NucleusCore::NotFound, "not found" },
      determine_signal: ->(_) { :wait }
    )
    add_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end

class RollbackWorkflow < NucleusCore::Workflow::Graph
  def define
    start_node(continue: :started, raise_exception: :unhandled_exception)
    add_node(
      state: :started,
      operation: lambda do |context|
        context.total ||= 0
        context.total += 1
      end,
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :running }
    )
    add_node(
      state: :running,
      operation: ->(context) { context.total += 1 },
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :sprinting }
    )
    add_node(
      state: :sprinting,
      operation: ->(context) { context.total += 1 },
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :stopped }
    )
    add_node(
      state: :stopped,
      determine_signal: ->(_) { :wait }
    )
  end
end

class ChainOfCommandWorkflow < NucleusCore::Workflow::Graph
  def define
    @execution = :chain_of_command

    start_node(continue: :one)
    add_node(
      state: :one,
      operation: ->(context) { context.fail!(message: "one_failed") },
      signals: { continue: :two }
    )
    add_node(
      state: :two,
      operation: ->(context) { context.fail!(message: "two_failed") },
      signals: { continue: :three }
    )
    add_node(
      state: :three,
      operation: ->(context) { context.fail!(message: "three_failed") },
      signals: { continue: :four }
    )
    add_node(
      state: :four,
      operation: ->(context) { context.fail!(message: "four_failed") },
      determine_signal: ->(_) { :wait }
    )
  end
end
