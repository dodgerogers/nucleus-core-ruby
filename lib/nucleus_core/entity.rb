# frozen_string_literal: false

require "forwardable"

module NucleusCore
  # Entity provides a flexible attribute container with dynamic method access.
  #
  # This class acts as a simple key-value store where attributes can be accessed
  # and modified dynamically using both method calls and hash-like access.
  #
  # Features:
  # - Supports method-style access (e.g., `obj.some_key` instead of `obj[:some_key]`).
  # - Handles both symbol and string keys interchangeably.
  # - Allows dynamic attribute assignment (e.g., `obj.some_key = "value"`).
  # - Provides JSON serialization methods (`to_json`, `as_json`).
  # - Supports `dig` and `delete` via delegation.
  #
  # Example Usage:
  #   obj = NucleusCore::Entity.new(foo: "bar")
  #   obj.foo  # => "bar"
  #   obj[:foo] # => "bar"
  #   obj.foo = "baz"
  #   obj.to_h  # => { foo: "baz" }
  class Entity
    extend Forwardable

    def_delegators :@__attributes__, :dig, :delete

    def initialize(attrs={})
      @__attributes__ = attrs
    end

    # rubocop:disable Style/MissingRespondToMissing
    def method_missing(name, *args)
      name_str = name.to_s
      if name_str.end_with?("=")
        self[name_str.chomp("=").to_sym] = args.first
      else
        self[name]
      end
    end
    # rubocop:enable Style/MissingRespondToMissing

    def to_h
      @__attributes__
    end

    def [](key)
      sym_key = key&.to_sym
      return @__attributes__[sym_key] if @__attributes__.key?(sym_key)

      str_key = key.to_s
      return @__attributes__[str_key] if @__attributes__.key?(str_key)

      @__attributes__[key]
    end

    def []=(key, value)
      sym_key = key.to_sym
      if @__attributes__.key?(sym_key)
        @__attributes__[sym_key] = value
      elsif @__attributes__.key?(str_key = key.to_s)
        @__attributes__[str_key] = value
      else
        @__attributes__[key] = value
      end
    end

    def key?(key)
      return true if @__attributes__.key?(key.to_sym)
      return true if @__attributes__.key?(key.to_s)

      @__attributes__.key?(key)
    end

    def to_json(options=nil)
      to_h.to_json(options)
    end

    def as_json(options=nil)
      to_h.as_json(options)
    end
  end
end
