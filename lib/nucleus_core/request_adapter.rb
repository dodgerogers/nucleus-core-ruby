require "nucleus_core/simple_object"

module NucleusCore
  class RequestAdapter < NucleusCore::SimpleObject
    def initialize(attrs=nil)
      attrs ||= {}
      attributes = defaults
        .merge(attrs)
        .slice(*defaults.keys)

      super(attributes)
    end

    private

    def defaults
      {
        format: NucleusCore.configuration.default_response_format,
        parameters: {}
      }
    end
  end
end
