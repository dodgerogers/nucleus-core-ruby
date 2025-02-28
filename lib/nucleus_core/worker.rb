module NucleusCore
  # This module defines a framework for asynchronous method execution within the NucleusCore framework.
  # The Worker class provides an interface for executing methods asynchronously using a specified adapter.
  # The Adapter class handles the actual invocation of the specified methods, either synchronously or asynchronously.
  #
  # NucleusCore::Worker:
  # - Manages the arguments and provides a mechanism for specifying and retrieving a queue adapter.
  # - The `call` method is intended to be overridden by subclasses to implement specific business logic.
  #
  # NucleusCore::Worker::Adapter:
  # - Provides methods to execute methods either asynchronously (`execute_async`) or synchronously (`execute`).
  # - Uses the NucleusCore::Connector class to dynamically invoke methods on specified classes.
  #
  # Example usage:
  #   class MyWorker < NucleusCore::Worker
  #     queue_adapter :active_job
  #
  #     def call
  #       # Implement business logic here
  #     end
  #   end
  #
  #   MyWorker.call(key: 'value')
  #
  # Detailed Description of Methods:
  #
  # NucleusCore::Worker::Adapter.execute_async(class_name, method_name, args)
  # - Executes the specified method asynchronously by invoking `execute`.
  #
  # NucleusCore::Worker::Adapter.execute(class_name, method_name, args)
  # - Uses NucleusCore::Connector to dynamically invoke the specified method on the given class.
  # - If the class is a subclass of NucleusCore::Worker, it instantiates the class with the provided
  #  arguments and calls the method.
  #
  # NucleusCore::Worker.queue_adapter(adapter=nil)
  # - Sets or retrieves the queue adapter for the Worker class.
  #
  # NucleusCore::Worker.call(args={})
  # - Validates the adapter and invokes the specified method asynchronously using the adapter.
  #
  # NucleusCore::Worker#call
  # - Abstract method to be implemented by subclasses, raising NotImplementedError if not overridden.
  #
  # Attributes:
  # - args: The arguments to be passed to the method.
  #
  # Raises:
  # - NotImplementedError: If the `call` method is not implemented in a subclass.
  # - RuntimeError: If the specified adapter does not subclass `NucleusCore::Worker::Adapter`.
  class Worker
    class Adapter
      def self.execute_async(class_name, method_name, args)
        execute(class_name, method_name, args)
      end

      def execute_async(class_name, method_name, args)
        Adapter.execute(class_name, method_name, args)
      end

      def self.execute(class_name, method_name, args)
        NucleusCore::Connector.execute(class_name, method_name, args) do |klass|
          return klass.new(args).send(method_name) if Utils.subclass?(klass, NucleusCore::Worker)
        end
      end
    end

    attr_reader :args

    @queue_adapter = nil

    def initialize(args)
      @args = args
    end

    def self.queue_adapter(adapter=nil)
      @queue_adapter = adapter if adapter

      @queue_adapter
    end

    def self.call(args={})
      adapter = args.delete(:adapter) || queue_adapter

      unless Utils.subclass?(adapter, NucleusCore::Worker::Adapter)
        raise "`#{adapter}` does not subclass `NucleusCore::Worker::Adapter`"
      end

      class_name = args.delete(:class_name) || name
      method_name = args.delete(:method_name) || :call
      arguments = args.delete(:args) || args

      adapter.execute_async(class_name, method_name, arguments)
    end

    def call
      raise NotImplementedError
    end
  end
end
