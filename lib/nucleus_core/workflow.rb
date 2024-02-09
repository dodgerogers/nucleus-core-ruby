# rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/ClassLength, Metrics/AbcSize:
module NucleusCore
  class Workflow
    class Node
      attr_reader :state, :operation, :rollback, :signals, :prepare_context, :determine_signal

      def initialize(attrs={})
        @state = attrs[:state]
        @operation = attrs[:operation]
        @rollback = attrs[:rollback]
        @signals = attrs[:signals]
        @prepare_context = attrs[:prepare_context]
        @determine_signal = attrs[:determine_signal]
      end
    end

    class Process
      attr_accessor :state, :visited, :repository, :persistance_method

      def initialize(state, opts={})
        @state = state
        @visited = []
        @repository = opts[:repository]
        @persistance_method = opts[:persistance_method]
      end

      def persist(state)
        config = NucleusCore.configuration
        repo = repository || config.workflow_process_repository
        method_name = persistance_method || config.workflow_process_persistance_method
        attemp_persist = repo && method_name
        persisted = repo&.send(method_name, self, state: state) != false

        return false if attemp_persist && !persisted

        @state = state
        @visited.push(state)

        true
      rescue StandardError
        false
      end
    end

    INITIAL_STATE = :initial
    CONTINUE = :continue
    WAIT = :wait
    OK = :ok
    FAILED = :failed

    attr_accessor :process, :nodes, :context

    def initialize(process: nil, context: {})
      @nodes = {}
      @process = process || Process.new(INITIAL_STATE)
      @context = build_context(context)

      init_nodes
    end

    def register_node(node_attrs={})
      node = Node.new(node_attrs)
      state = node.state

      raise ArgumentError.new(message: "state `#{state}` is already defined") if nodes.key(state)

      nodes[state] = node
    end

    def start_node(signals={})
      raise ArgumentError, "#{self.class}##{__method__}: missing signals" if signals.empty?

      register_node(state: INITIAL_STATE, signals: signals)
    end

    def init_nodes
      define
    end

    def define
    end

    def self.call(signal: nil, process: nil, context: {})
      workflow = new(process: process, context: context)

      workflow.validate_nodes!
      workflow.execute(signal)

      [workflow.context, workflow.process]
    end

    def self.rollback(process:, context:)
      workflow = new(process: process, context: context)
      visited = workflow.process.visited.clone

      visited.reverse_each do |state|
        node = workflow.nodes[state]

        next node.operation.rollback(context) if node.operation.is_a?(NucleusCore::Operation)
        next node.rollback.call(context) if node.rollback.is_a?(Proc)
      end
    end

    def validate_nodes!
      start_nodes = nodes.values.count do |node|
        node.state == INITIAL_STATE
      end

      raise ArgumentError, "#{self.class}: missing `:initial` start node" if start_nodes.zero?
      raise ArgumentError, "#{self.class}: more than one start node detected" if start_nodes > 1
    end

    # rubocop:disable Metrics/MethodLength
    def execute(signal=nil)
      signal ||= CONTINUE
      current_state = process.state
      next_signal = (fetch_node(current_state)&.signals || {})[signal]
      current_node = fetch_node(next_signal)

      context.fail!("invalid signal: #{signal}") if current_node.nil?

      while next_signal
        status, next_signal, @context = execute_node(current_node, context)

        break if status == FAILED

        if process.persist(current_node.state) == false
          message = "#{self.class.name} failed to persist process state: `#{current_node.state}`"
          context.fail!(message)
        end

        current_node = fetch_node(next_signal)

        break if next_signal == WAIT
      end

      context
    rescue NucleusCore::Operation::Context::Error
      context
    rescue StandardError => e
      fail_context(@context, e)
    end
    # rubocop:enable Metrics/MethodLength

    private

    def build_context(context={})
      return context if context.is_a?(NucleusCore::Operation::Context)

      NucleusCore::Operation::Context.new(context)
    end

    def execute_node(node, context)
      context = prepare_context(node, context)
      operation = node.operation

      operation&.call(context)

      status = context.success? ? OK : FAILED
      next_signal = determine_signal(node, context)

      [status, next_signal, context]
    end

    def prepare_context(node, context)
      return node.prepare_context.call(context) if node.prepare_context.is_a?(Proc)
      return send(node.prepare_context, context) if node.prepare_context.is_a?(Symbol)

      context
    end

    def determine_signal(node, context)
      signal = CONTINUE
      signal = node.determine_signal.call(context) if node.determine_signal.is_a?(Proc)
      signal = send(node.determine_signal, context) if node.determine_signal.is_a?(Symbol)
      node_signals = node.signals || {}

      node_signals[signal]
    end

    def fetch_node(state)
      nodes[state]
    end

    def fail_context(context, exception)
      message = "Unhandled exception #{self.class}: #{exception.message}"

      context.fail!(message, exception: exception)
    rescue NucleusCore::Operation::Context::Error
      context
    end
  end
end
# rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/ClassLength, Metrics/AbcSize:
