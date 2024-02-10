# rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize:
module NucleusCore
  module Workflow
    class Manager
      # Signals
      #########################################################################
      CONTINUE = :continue
      WAIT = :wait

      # Statuses
      #########################################################################
      OK = :ok
      FAILED = :failed

      attr_accessor :process, :graph, :context

      def initialize(process:, graph:, context: {})
        @process = process || NucleusCore::Workflow::Process.new(graph.initial_state)
        @graph = graph
        @context = build_context(context)
      end

      # rubocop:disable Metrics/MethodLength
      def call(signal=nil)
        signal ||= CONTINUE
        current_state = process.state
        next_signal = (graph.fetch_node(current_state)&.signals || {})[signal]
        current_node = graph.fetch_node(next_signal)

        context.fail!("invalid signal: #{signal}") if current_node.nil?

        while next_signal
          status, next_signal, @context = execute_node(current_node, context)

          break if status == FAILED

          if process.save(current_node.state) == false
            message = "#{graph.class.name} failed to persist process state: `#{current_node.state}`"
            context.fail!(message)
          end

          current_node = graph.fetch_node(next_signal)

          break if next_signal == WAIT
        end

        context
      rescue NucleusCore::Operation::Context::Error
        context
      rescue StandardError => e
        fail_context(@context, e)
      end
      # rubocop:enable Metrics/MethodLength

      def rollback
        visited = process.visited.clone

        visited.reverse_each do |state|
          node = graph.fetch_node(state)

          node.operation.rollback(context) if node.operation.is_a?(NucleusCore::Operation)
          node.rollback.call(context) if node.rollback.is_a?(Proc)

          # TODO: what if saving fails?
          process.save(state)
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
