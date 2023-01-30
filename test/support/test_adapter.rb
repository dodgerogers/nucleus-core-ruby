class TestAdapter
  Nucleus::Configuration::ADAPTER_METHODS.each do |adapter_method|
    define_singleton_method(adapter_method) do |entity|
      entity
    end
  end
end
