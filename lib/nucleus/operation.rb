module Nucleus
  class Operation
    class Context < OpenStruct
      class Error < StandardError
        attr_reader :exception

        def initialize(message, opts={})
          @exception = opts[:exception]

          super(message)
        end
      end

      attr_reader :failure, :executed

      def initialize(attrs={})
        @failure = false
        @executed = attrs.fetch(:executed) { [] }

        super(attrs)
      end

      def success?
        !@failure
      end

      def fail!(message, attrs={})
        @failure = true

        self.message = message
        self.exception = attrs.delete(:exception)

        raise Context::Error, message
      end

      def execute(operation)
        @executed.push(operation)
      end
    end

    attr_reader :context

    def initialize(args={})
      @context = if args.is_a?(Context)
                   args
                 else
                   Context.new(args)
                 end
    end

    def self.call(args={})
      operation = new(args)
      context = operation.context

      operation.call
      context.execute(self.class)

      context
    rescue Context::Error
      context
    end

    def self.rollback(context)
      context.executed.reverse_each do |executed|
        executed.new(context).rollback
      end
    end

    def call
    end

    def rollback
    end
  end
end
