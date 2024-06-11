module NucleusCore
  class Worker
    class Adapter
      def self.execute_async(class_name, method_name, args)
        execute(class_name, method_name, args)
      end

      def execute_async(class_name, method_name, args)
        Adapter.execute(class_name, method_name, args)
      end

      def self.execute(class_name, method_name, args)
        klass = Utils.to_const(class_name.to_s)
        worker = Utils.subclass_of(klass, NucleusCore::Worker)

        return klass.new(args).send(method_name) if worker

        klass.send(method_name, args)
      end
    end

    attr_reader :args

    def initialize(args)
      @args = args
    end

    def self.call(args={})
      adapter = args.delete(:adapter)

      unless Utils.subclass_of(adapter, NucleusCore::Worker::Adapter)
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
