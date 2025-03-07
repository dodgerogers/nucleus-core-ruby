module NucleusCore
  class Operation
    # The Operation class serves as a base class for defining and executing business operations
    # within the NucleusCore framework. It encapsulates the logic for performing a specific task
    # and provides a structured context for managing state, handling errors, and validating required arguments.
    #
    # Key Features:
    # - Context Management: Encapsulates state and attributes within an Operation::Context object,
    #   allowing for easy access and manipulation of operation data.
    # - Error Handling: Provides a mechanism to fail the operation and propagate errors using the Context::Error class.
    # - Required Arguments Validation: Offers a built-in method to validate the presence of required arguments.
    # - Operation Execution: Supports defining custom `call` and `rollback` methods to implement the core logic of
    #   the operation.
    #
    # Usage:
    # - Subclass the Operation class and override the `call` and `rollback` methods to define the operation's behavior.
    # - Use the `context` attribute to access and manipulate operation data.
    # - Implement the `required_args` method to specify arguments that must be present for the operation to proceed.
    #
    # Example:
    # class MyOperation < NucleusCore::Operation
    #   def required_args
    #     [:arg1, :arg2]
    #   end
    #
    #   def call
    #     validate_required_args! do |missing|
    #       missing.push('id or order') if context.id.nil? && context.order.nil?
    #     end
    #
    #     # Perform operation logic
    #   end
    #
    #   def rollback
    #     # Define rollback logic
    #   end
    # end
    #
    # NucleusCore::Operation::Context:
    # - Handles the state of the operation, including success and failure states.
    # - Provides a method to mark the operation as failed and raise an appropriate error.
    #
    class Context < Entity
      class Error < StandardError; end

      attr_reader :failure
      attr_accessor :message, :exception

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
      operation.tap(&:call).context
    rescue Context::Error
      operation&.context
    end

    def self.rollback(context)
      operation = new(context)
      operation.tap(&:rollback).context
    end

    def validate_required_args!
      missing = (required_args || []).reject { context.key?(_1) }
      yield missing if block_given?
      context.fail!("Missing required arguments: #{missing.join(', ')}") if missing.any?
    end

    # Public interface
    ##################
    def call
    end

    def rollback
    end

    def required_args
      []
    end
    ##################
  end
end
