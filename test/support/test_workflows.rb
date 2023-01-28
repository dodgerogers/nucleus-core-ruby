require "nucleus"

class SimpleWorkflow < Nucleus::Workflow
  def define
    register_node(
      state: :initial,
      signals: { continue: :started }
    )
    register_node(
      state: :started,
      operation: ->(context) { context.total += 1 },
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

class FailingWorkflow < Nucleus::Workflow
  def define
    register_node(
      state: :initial,
      signals: { continue: :failed }
    )
    register_node(
      state: :failed,
      operation: ->(context) { context.fail!("worfkflow error!") },
      determine_signal: { continue: :completed }
    )
    register_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end

class RollbackWorkflow < Nucleus::Workflow
  def define
    register_node(
      state: :initial,
      signals: { continue: :started }
    )
    register_node(
      state: :started,
      operation: ->(context) { context.total += 1 },
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
