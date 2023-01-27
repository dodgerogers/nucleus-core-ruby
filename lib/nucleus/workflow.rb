module Nucleus
  class Workflow
    class Node
      attr_reader :state, :operation, :signals, :prepare_context, :determine_signal

      def initialize(attrs={})
        @state = attrs[:state]
        @operation = attrs[:operation]
        @signals = attrs[:signals]
        @prepare_context = attrs[:prepare_context]
        @determine_signal = attrs[:determine_signal]
      end
    end

    class Process
      attr_accessor :state, :visited

      def initialize(state)
        @state = state
        @visited = []
      end

      def visit(state)
        @state = state
        @visited.push(state)
      end
    end

    # States
    ###########################################################################
    INITIAL_STATE = :initial

    # Signals
    ###########################################################################
    CONTINUE = :continue
    WAIT = :wait

    # Node statuses
    ###########################################################################
    OK = :ok
    FAILED = :failed

    attr_accessor :process, :nodes, :context

    def initialize(process: nil, context: {})
      @nodes = {}
      @process = process || Process.new(INITIAL_STATE)
      @context = build_context(context)
    end

    def register_node(attrs = {})
      node = Node.new(attrs)

      @nodes[node.state] = node
    end

    def init_nodes
      define
    end

    # Define the graph here
    def define
    end
    
    def self.call(signal: nil, process: nil, context: {})
      workflow = new(process: process, context: context)

      workflow.init_nodes
      workflow.validate_nodes!
      workflow.execute(signal)

      return workflow.context, workflow.process
    end

    def validate_nodes!
      start_nodes = nodes.values.filter {|node| node.state == INITIAL_STATE }.size

      raise ArgumentError, "#{self.class}: missing `:initial` start node" if start_nodes.zero?
      raise ArgumentError, "#{self.class}: more than one start node detected" if start_nodes > 1
    end

    def execute(signal=nil)
      signal = signal || CONTINUE
      current_state = process.state
      next_signal = (fetch_node(current_state)&.signals || {})[signal]
      current_node = fetch_node(next_signal)

      context.fail!("invalid signal: #{signal}") if current_node.nil?
      
      while next_signal
        result = execute_node(current_node, context)
        status, next_signal, context = result

        break if status == FAILED

        process.visit(current_node.state)
        current_node = fetch_node(next_signal)

        break if next_signal == WAIT
      end

      context
    rescue Nucleus::Operation::Context::Error
      context
    rescue StandardError => e
      fail_context(@context, e)
    end

    private

    def build_context(context={})
      return context if context.is_a?(Nucleus::Operation::Context)

      Nucleus::Operation::Context.new(context)
    end

    def execute_node(node, context)
      context = prepare_context(node, context)
      operation = node.operation
      
      operation && operation.call(context)

      status = context.success? ? OK : FAILED
      next_signal = determine_signal(node, context)

      return status, next_signal, context
    end

    def prepare_context(node, context)
      return node.prepare_context.call(context) if node.prepare_context.is_a?(Proc)
      return self.send(node.prepare_context, context) if node.prepare_context.is_a?(Symbol)
      return context
    end

    def determine_signal(node, context)
      signal = CONTINUE
      signal = node.determine_signal.call(context) if node.determine_signal.is_a?(Proc)
      signal = self.send(node.determine_signal, context) if node.determine_signal.is_a?(Symbol)
      node_signals = node.signals || {}

      return node_signals[signal]
    end

    def fetch_node(state)
      nodes[state]
    end

    def fail_context(context, exception)
      message = "Unhandled exception #{self.class}: #{exception.message}"

      context.fail!(message, exception: exception)
    rescue Nucleus::Operation::Context::Error
      context
    end
  end
end
