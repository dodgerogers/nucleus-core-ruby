require "nucleus_core/simple_object"

class NucleusCore::RequestAdapter < NucleusCore::SimpleObject
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
      cookies: {},
      format: NucleusCore.configuration.default_response_format,
      headers: {},
      parameters: {},
      session: {},
      context: {}
    }
  end
end
