module NucleusCore
  # This class serves as a utility for dynamically invoking methods within a specified class in the framework.
  # The Connector class is designed to adapt a business logic method call to execute a corresponding method
  # within the framework. It takes a class name, method name, and arguments, converts the class name to a
  # constant, and then invokes the specified method with the provided arguments. This class also supports
  # an optional block, allowing further customization or configuration of the class before the method is called.
  #
  # Example usage:
  #   NucleusCore::Connector.execute('SomeClass', 'some_method', { key: 'value' }) do |klass|
  #     # Perform additional configuration or setup on klass if needed
  #   end
  #
  # Params:
  # - class_name: The name of the class containing the method to be executed.
  # - method_name: The name of the method to be invoked.
  # - args: The arguments to be passed to the method.
  #
  # Returns:
  # - The result of the invoked method.
  #
  # Raises:
  # - No explicit exceptions are raised by this class, but exceptions from the invoked method may propagate.
  class Connector
    def self.execute(class_name, method_name, args)
      klass = Utils.to_const(class_name.to_s)

      yield klass if block_given?

      klass.send(method_name, args)
    end
  end
end
