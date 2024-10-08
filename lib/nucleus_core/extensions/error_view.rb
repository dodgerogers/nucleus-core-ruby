require "nucleus_core/view"

class NucleusCore::ErrorView < NucleusCore::View
  def initialize(attrs={})
    view_attrs = {
      status: attrs.fetch(:status, :internal_server_error),
      message: attrs.fetch(:message, nil),
      errors: attrs.fetch(:errors, [])
    }

    super(view_attrs)
  end

  def json
    NucleusCore::View::Response.new(:json, content: to_h, status: status)
  end
end
