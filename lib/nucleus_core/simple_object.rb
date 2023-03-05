module NucleusCore
  class SimpleObject
    attr_reader :__attributes__

    def initialize(attrs={})
      @__attributes__ = {}

      attrs.each_pair do |key, value|
        define_singleton_method(key) do
          instance_variable_get("@#{key}")
        end

        define_singleton_method("#{key}=") do |val|
          instance_variable_set("@#{key}", val)
          @__attributes__[key] = val
        end

        instance_variable_set("@#{key}", value)
        @__attributes__[key] = value
      end
    end

    def to_h
      __attributes__
    end
  end
end
