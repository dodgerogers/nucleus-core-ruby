module NucleusCore
  module Workflow
    class Process
      attr_reader :state
      attr_accessor :reference, :visited

      def initialize(state, opts={})
        @state = state
        @visited = []
        @reference = opts[:reference]
      end

      def state=(state)
        @state = state
        @visited.push(state)
      end
    end
  end
end
