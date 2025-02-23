module NucleusCore
  class RequestAdapter < NucleusCore::Entity
    def initialize(attrs=nil)
      attrs ||= {}

      super(
        defaults.merge!(attrs) do |k, v1, v2|
          if (k == :format && v2.nil?) || v2.empty?
            v1
          else
            v2
          end
        end
      )
    end

    private

    def defaults
      {
        format: NucleusCore.configuration.default_response_format
      }
    end
  end
end
