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
  # - Handles both symbol and string key access interchangeably.
  # - Allows dynamic attribute assignment (e.g., `obj.some_key = "value"`).
  # - Provides JSON serialization methods (`to_json`, `as_json`).
  # - Supports `each`, `delete`, `dig`, `map`, and `merge!` via delegation.
  #
  # Example Usage:
  #   obj = NucleusCore::Entity.new(foo: "bar", nested: { "object": "value" })
  #   obj.foo  # => "bar"
  #   obj[:foo] # => "bar"
  #   obj['foo'] # => "bar"
  #   obj.dig(:nested, :object) = "value"
  #   obj.foo = "baz"
  #   obj.to_h  # => { foo: "baz", nested: { object: "value" } }
  class Entity
    extend Forwardable

    HASH_METHODS = %i[each delete dig map keys].freeze
    def_delegators :@__properties__, *HASH_METHODS

    def initialize(props={})
      @__properties__ = symbolize_keys(props || {})
    end

    def [](key)
      @__properties__[format_key(key)]
    end

    def []=(key, value)
      @__properties__[format_key(key)] = value
    end

    def to_h
      @__properties__
    end

    def to_json(options=nil)
      to_h.to_json(options)
    end

    def as_json(options=nil)
      to_h.as_json(options)
    end

    def initialize_copy(other)
      super
      @__properties__ = Marshal.load(Marshal.dump(other.to_h))
    end

    def inspect
      "#<#{self.class.name}:#{object_id} #{@__properties__.inspect}>"
    end

    def key?(key)
      @__properties__.key?(format_key(key))
    end

    def merge!(props={})
      @__properties__.merge!(symbolize_keys(props))
    end

    def method_missing(name, *args)
      name_str = name.to_s
      if name_str.end_with?("=")
        self[name_str.chomp("=")] = args.first
      else
        self[format_key(name)]
      end
    end

    def respond_to?(name, _include_all=nil)
      key?(name) || super
    end

    def respond_to_missing?(name, _include_private=false)
      key?(name) || super
    end

    private

    def symbolize_keys(hash)
      hash ||= {}
      hash.each_with_object({}) do |(k, v), acc|
        acc[format_key(k)] =
          case v
          when Hash
            symbolize_keys(v)
          when Array
            v.map { _1.is_a?(Hash) ? symbolize_keys(_1) : _1 }
          else
            v
          end
      end
    end

    def format_key(key)
      (key.is_a?(Symbol) && key) || key.to_s.to_sym
    end
  end
end
