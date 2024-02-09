class SimpleWorkflow < NucleusCore::Workflow
  def define
    start_node(continue: :started)
    register_node(
      state: :started,
      operation: lambda do |context|
        context.total ||= 0
        context.total += 1
      end,
      determine_signal: ->(context) { context.total > 10 ? :pause : :stop },
      signals: { pause: :paused, stop: :stopped }
    )
    register_node(
      state: :paused,
      signals: { continue: :stopped }
    )
    register_node(
      state: :stopped,
      operation: ->(context) { context.total += 2 },
      determine_signal: ->(_) { :wait }
    )
  end
end

class FailingWorkflow < NucleusCore::Workflow
  def define
    start_node(continue: :failed, raise_exception: :unhandled_exception)
    register_node(
      state: :failed,
      operation: ->(context) { context.fail!("workflow error!") },
      signals: { continue: :completed }
    )
    register_node(
      state: :unhandled_exception,
      operation: ->(_context) { raise NucleusCore::NotFound, "not found" },
      determine_signal: ->(_) { :wait }
    )
    register_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end

class RollbackWorkflow < NucleusCore::Workflow
  def define
    start_node(continue: :started)
    register_node(
      state: :started,
      operation: lambda do |context|
        context.total ||= 0
        context.total += 1
      end,
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :running }
    )
    register_node(
      state: :running,
      operation: ->(context) { context.total += 1 },
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :sprinting }
    )
    register_node(
      state: :sprinting,
      operation: ->(context) { context.total += 1 },
      rollback: ->(context) { context.total -= 1 },
      signals: { continue: :stopped }
    )
    register_node(
      state: :stopped,
      determine_signal: ->(_) { :wait }
    )
  end
end
