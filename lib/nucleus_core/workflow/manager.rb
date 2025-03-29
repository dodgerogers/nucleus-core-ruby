# rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize:
module NucleusCore
  module Workflow
    # The Manager class orchestrates the execution and management of workflow processes
    # within the NucleusCore framework. It leverages a graph of nodes to determine the
    # sequence of operations based on transitions and the current state of the process.
    #
    # Key Features:
    # - Workflow Execution: Manages the progression through the workflow nodes based on
    #   transitions, executing node operations, and updating the process state.
    # - Context Management: Utilizes a context object to maintain and manipulate the state
    #   and data throughout the workflow execution.
    # - Error Handling: Handles and logs errors encountered during the workflow execution,
    #   providing mechanisms for rolling back operations if needed.
    #
    # Usage:
    # - Instantiate the Manager with a process, graph, and context.
    # - Use the `call` method to execute the workflow, optionally providing a signal to start with.
    # - Use the `rollback` method to revert the operations performed during the workflow execution.
    #
    # Example:
    # manager = NucleusCore::Workflow::Manager.new(process: my_process, graph: my_graph, context: my_context)
    # manager.call
    #
    # Attributes:
    # - process: The workflow process, representing the current state and history of the execution.
    # - graph: The workflow graph, defining the nodes and transitions based on transitions.
    # - context: The context object, maintaining the state and data throughout the workflow.
    #
    # Methods:
    # - call: Executes the workflow, progressing through nodes based on transitions and updating the process state.
    # - rollback: Reverts the operations performed during the workflow execution, providing a mechanism for recovery.
    #
    class Manager
      # transitions
      #########################################################################
      CONTINUE = :continue
      WAIT = :wait

      # Statuses
      #########################################################################
      OK = :ok
      FAILED = :failed

      attr_reader :process, :graph, :context

      def initialize(process:, graph:, context: {})
        @process = process || NucleusCore::Workflow::Process.new(graph.class::INITIAL_STATE)
        @graph = graph
        @context = build_context(context)
      end

      def call(signal=nil)
        signal ||= CONTINUE
        current_state = process.state
        next_signal = (graph.fetch_node(current_state)&.transitions || {})[signal]
        current_node = graph.fetch_node(next_signal)

        context.fail!("invalid signal: #{signal}") if current_node.nil?

        while next_signal
          status, next_signal, @context = execute_node(current_node, context)

          break if status == FAILED && !graph.continue_on_failure?

          process.state = current_node.state

          yield process.state if block_given?

          current_node = graph.fetch_node(next_signal)

          break if next_signal == WAIT
        end

        context
      rescue NucleusCore::Operation::Context::Error
        context
      rescue StandardError => e
        fail_context(@context, e)
      end

      def rollback
        visited = process.visited.clone

        visited.reverse_each do |state|
          node = graph.fetch_node(state)

          node.operation.rollback(context) if node.operation.is_a?(NucleusCore::Operation)
          node.rollback.call(context) if node.rollback.is_a?(Proc)

          yield state if block_given?
        end

        nil
      end

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
      rescue NucleusCore::Operation::Context::Error => e
        if graph.continue_on_failure?
          next_signal = determine_signal(node, context)

          return [OK, next_signal, context]
        end

        raise e
      end

      def prepare_context(node, context)
        if node.prepare_context.is_a?(Proc)
          node.prepare_context.call(context)
        elsif node.prepare_context.is_a?(Symbol)
          send(node.prepare_context, context)
        else
          context
        end
      end

      def determine_signal(node, context)
        signal = CONTINUE
        if node.determine_signal.is_a?(Proc)
          signal = node.determine_signal.call(context)
        elsif node.determine_signal.is_a?(Symbol)
          signal = send(node.determine_signal, context)
        end

        node.transitions&.dig(signal)
      end

      def fail_context(context, exception)
        message = "Unhandled exception #{graph.class}: #{exception.message}"

        context.fail!(message, exception: exception)
      rescue NucleusCore::Operation::Context::Error
        context
      end
    end
  end
end
# rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize:
