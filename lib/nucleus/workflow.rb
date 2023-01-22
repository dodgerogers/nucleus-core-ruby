module Nucleus
  class Workflow
    class Process
      attr_accessor :state

      def initialize
        @state = :initial
      end
    end

    attr_accessor :process, :state

    def initialize(args={})
      @process = args.fetch(:process) { Process.new }
      @state = @process&.state || :initial
    end

    def self.call(args={})
      signal = args[:signal] || :initial # graph.nodes.first.signal
      workflow = new(args)
      workflow.execute(signal)
    end

    def graph
    end

    def execute
    end
  end
end
