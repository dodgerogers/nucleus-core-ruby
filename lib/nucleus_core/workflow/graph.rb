require "singleton"

module NucleusCore
  module Workflow
    class Graph
      include Singleton

      INITIAL_STATE = :initial
      CONTINUE_ON_FAILURE = :continue
      HALT_ON_FAILURE = :halt

      def initialize
        @graph_definition = self.class.graph_definition
        @failure_handling = self.class.failure_handling
      end

      def self.graph_definition
        @graph_definition ||= {}
      end

      def self.failure_handling(value=nil)
        if value && ![CONTINUE_ON_FAILURE, HALT_ON_FAILURE].include?(value)
          raise ArgumentError, "Invalid failure handling: #{value}"
        end

        @failure_handling ||= value || HALT_ON_FAILURE
      end

      def self.initial(&node_block)
        node(:initial, &node_block)
      end

      def self.node(state, &node_block)
        raise ArgumentError, "state #{state} is already defined" if graph_definition.key?(state)

        node = Node.new(state: state)

        graph_definition[state] = node

        node.instance_eval(&node_block) if node_block
      end

      def self.define_graph(&block)
        instance_eval(&block)

        graph_definition.freeze
      end

      def continue_on_failure?
        @failure_handling == CONTINUE_ON_FAILURE
      end

      def fetch_node(state)
        @graph_definition[state]
      end

      def self.call(signal: nil, process: nil, context: nil)
        manager = Manager.new(process: process, context: context, graph: instance)
        context = manager.call(signal) { |state| handle_execution_step(state) }

        yield manager if block_given?

        context
      end

      def self.rollback(process:, context:)
        manager = Manager.new(process: process, context: context, graph: instance)
        context = manager.rollback { |state| handle_revertion_step(state) }

        yield manager if block_given?

        context
      end

      def self.handle_execution_step(process)
        # Implement in subclasses to handle execution steps
      end

      def self.handle_revertion_step(process)
        # Implement in subclasses to handle reversion steps
      end
    end
  end
end
