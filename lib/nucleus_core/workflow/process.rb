module NucleusCore
  module Workflow
    class Process
      attr_accessor :state, :reference, :visited

      def initialize(state, opts={})
        @state = state
        @visited = []
        @reference = opts[:reference]
      end
    end
  end
end
