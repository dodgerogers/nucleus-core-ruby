class TestAdapter
  # Iterates through each of the required methods of a response adapter and
  # defines a method which just returns the parameter.
  NucleusCore::Configuration::ADAPTER_METHODS.each do |adapter_method|
    define_singleton_method(adapter_method) do |entity|
      entity
    end
  end
end
