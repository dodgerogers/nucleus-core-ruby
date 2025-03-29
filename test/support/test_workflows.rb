class SimpleWorkflow < NucleusCore::Workflow::Graph
  define_graph do
    initial do
      transitions continue: :started
    end

    node :started do
      operation lambda { |context|
        context.total ||= 0
        context.total += 1
      }
      determine_signal ->(context) { context.total > 10 ? :pause : :stop }
      transitions pause: :paused, stop: :stopped
    end

    node :paused do
      transitions continue: :stopped
    end

    node :stopped do
      operation ->(context) { context.total += 2 }
      determine_signal ->(_ctx) { :wait }
    end
  end
end

class FailingWorkflow < NucleusCore::Workflow::Graph
  define_graph do
    initial do
      transitions continue: :failed, raise_exception: :unhandled_exception
    end

    node :failed do
      operation ->(context) { context.fail!("workflow error!") }
      transitions continue: :completed
    end

    node :unhandled_exception do
      operation ->(_context) { raise NucleusCore::NotFound, "not found" }
      determine_signal ->(_ctx) { :wait }
    end

    node :completed do
      determine_signal ->(_ctx) { :wait }
    end
  end
end

class RollbackWorkflow < NucleusCore::Workflow::Graph
  define_graph do
    initial do
      transitions continue: :started
    end

    node :started do
      operation lambda { |context|
        context.total ||= 0
        context.total += 1
      }
      rollback ->(context) { context.total -= 1 }
      transitions continue: :running
    end

    node :running do
      operation ->(context) { context.total += 1 }
      rollback ->(context) { context.total -= 1 }
      transitions continue: :sprinting
    end

    node :sprinting do
      operation ->(context) { context.total += 1 }
      rollback ->(context) { context.total -= 1 }
      transitions continue: :stopped
    end

    node :stopped do
      determine_signal ->(_ctx) { :wait }
    end
  end
end

class ChainOfCommandWorkflow < NucleusCore::Workflow::Graph
  define_graph do
    failure_handling :continue

    initial do
      transitions continue: :one
    end

    node :one do
      operation ->(context) { context.fail!(message: "one_failed") }
      transitions continue: :two
    end

    node :two do
      operation ->(context) { context.fail!(message: "two_failed") }
      transitions continue: :three
    end

    node :three do
      operation ->(context) { context.fail!(message: "three_failed") }
      transitions continue: :four
    end

    node :four do
      operation ->(context) { context.fail!(message: "four_failed") }
      determine_signal ->(_ctx) { :wait }
    end
  end
end

class WorkflowCallingWorkflow < NucleusCore::Workflow::Graph
  define_graph do
    initial do
      transitions continue: :first_graph
    end

    node :first_graph do
      operation ->(context) { SimpleWorkflow.call(context: context) }
      transitions continue: :second_graph
    end

    node :second_graph do
      operation ->(context) { SimpleWorkflow.call(context: context) }
      transitions continue: :finished
    end

    node :finished do
      determine_signal ->(_ctx) { :wait }
    end
  end
end
