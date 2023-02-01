module NucleusCore
  class BasicObject
    def initialize(attrs={})
      attrs.each_pair do |key, value|
        define_singleton_method(key.to_s) do
          instance_variable_get("@#{key}")
        end

        define_singleton_method("#{key}=") do |val|
          instance_variable_set("@#{key}", val)
        end

        instance_variable_set("@#{key}", value)
      end
    end

    def to_h
      instance_variables
        .reduce({}) do |acc, var|
        acc.merge(var.to_s.delete("@") => instance_variable_get(var))
      end
    end
  end
end
