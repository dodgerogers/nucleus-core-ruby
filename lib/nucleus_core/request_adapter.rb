module NucleusCore
  class RequestAdapter < NucleusCore::SimpleObject
    def initialize(attrs=nil)
      attrs ||= {}

      super(defaults.merge!(attrs))
    end

    private

    def defaults
      {
        format: NucleusCore.configuration.default_response_format
      }
    end
  end
end
