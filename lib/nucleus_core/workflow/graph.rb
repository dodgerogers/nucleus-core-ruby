module NucleusCore
  module Workflow
    class Graph
      INITIAL_STATE = :initial

      attr_accessor :nodes, :execution

      def initialize(opts={})
        @nodes = {}
        @execution = opts.fetch(:execution, :default)

        define

        validate_nodes!
      end

      def chain_of_command?
        execution&.to_sym == :chain_of_command
      end

      def define
      end

      def start_node(signals={})
        add_node(state: INITIAL_STATE, signals: signals)
      end

      def add_node(node_attrs={})
        raise ArgumentError.new(message: "state `#{state}` is already defined") if nodes.key(node_attrs[:state])

        NucleusCore::Workflow::Node.new(node_attrs).tap do |node|
          nodes[node.state] = node
        end
      end

      def fetch_node(state)
        nodes[state]
      end

      def self.call(signal: nil, process: nil, context: nil)
        manager = NucleusCore::Workflow::Manager.new(process: process, context: context, graph: new)

        manager.call(signal)

        manager
      end

      def self.rollback(process:, context:)
        manager = NucleusCore::Workflow::Manager.new(process: process, context: context, graph: new)

        manager.rollback

        manager
      end

      private

      def validate_nodes!
        start_nodes = nodes.values.count do |node|
          node.state == INITIAL_STATE
        end

        raise ArgumentError, "#{self.class}: missing `:initial` start node" if start_nodes.zero?
        raise ArgumentError, "#{self.class}: more than one start node detected" if start_nodes > 1
      end
    end
  end
end
