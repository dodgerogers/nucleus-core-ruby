module NucleusCore
  module Workflow
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
  end
end
