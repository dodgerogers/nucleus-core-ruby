require "nucleus"


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
      signals: { continue: :stopped }
    )
    register_node(
      state: :stopped,
      operation: lambda {|context| context.total += 2 },
      determine_signal: lambda {|_| :wait }
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
      operation: lambda {|context| context.fail!("worfkflow error!") },
      determine_signal: { continue: :completed }
    )
    register_node(
      state: :completed,
      determine_signal: lambda {|_| :wait }
    )
  end
end
