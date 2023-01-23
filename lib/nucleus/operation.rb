require 'ostruct'

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

      attr_reader :failure

      def initialize(attrs={})
        @failure = false

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
    end

    attr_reader :context

    def initialize(args={})
      @context = args.is_a?(Context) ? args : Context.new(args)
    end

    def self.call(args={})
      operation = new(args)

      operation.call
      
      return operation.context
    rescue Context::Error
      operation.context
    end

    def self.rollback(context)
      operation = new(context)

      operation.rollback

      return operation.context
    end

    def call
    end

    def rollback
    end
  end
end
