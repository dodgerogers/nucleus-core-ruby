class TestAdapter < NucleusCore::Worker::Adapter
  def self.execute_async(class_name, method_name, args={})
    super(class_name, method_name, args)
  end
end

class TestWorker < NucleusCore::Worker
  queue_adapter TestAdapter

  def call
    args.keys.join(", ")
  end
end
