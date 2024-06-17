class TestWorker < NucleusCore::Worker
  class Adapter < NucleusCore::Worker::Adapter
    def self.execute_async(class_name, method_name, args={})
      super(class_name, method_name, args)
    end
  end

  def call
    args.keys.join(", ")
  end
end
