module NucleusCore
  module Workflow
    class Process
      attr_accessor :state, :reference, :visited, :persistance_service, :persistance_method

      def initialize(state, opts={})
        @state = state
        @visited = []
        @reference = opts[:reference]
        @persistance_service = opts[:persistance_service]
        @persistance_method = opts[:persistance_method]
      end

      def save(state)
        attrs = { state: state, reference: reference }
        persisted = persistance_service&.send(persistance_method, self, attrs) != false

        return false if persistance_service && persistance_method && !persisted

        @state = state
        @visited.push(state)

        true
      rescue StandardError
        false
      end
    end
  end
end
