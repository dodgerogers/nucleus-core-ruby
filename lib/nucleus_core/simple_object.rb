# frozen_string_literal: false

require "forwardable"

module NucleusCore
  class SimpleObject
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

      @__attributes__[key.to_s]
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

    def to_json(options=nil)
      to_h.to_json(options)
    end

    def as_json(options=nil)
      to_h.as_json(options)
    end
  end
end
