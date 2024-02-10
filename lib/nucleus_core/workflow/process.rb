module NucleusCore
  module Workflow
    class Process
      attr_accessor :state, :reference, :visited, :repository, :save_method

      def initialize(state, opts={})
        @state = state
        @visited = []
        @reference = opts[:reference]
        @repository = opts[:repository]
        @save_method = opts[:save_method]
      end

      def save(state)
        attrs = { state: state, reference: reference }
        persisted = repository&.send(save_method, self, attrs) != false

        return false if repository && save_method && !persisted

        @state = state
        @visited.push(state)

        true
      rescue StandardError
        false
      end
    end
  end
end
