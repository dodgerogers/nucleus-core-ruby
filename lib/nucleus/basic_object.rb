module Nucleus
  class BasicObject
    def initialize(attrs={})
      attrs.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
    end
  end
end
