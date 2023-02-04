require "nucleus_core/response_adapters/response_adapter"
require "nucleus_core/views/view"

class NucleusCore::ErrorView < NucleusCore::View
  def initialize(attrs={})
    super(
      {}.tap do |a|
        a[:status] = attrs.fetch(:status, :unprocessable_entity)
        a[:message] = attrs.fetch(:message, nil)
        a[:errors] = attrs.fetch(:errors, [])
      end
    )
  end

  def json_response
    NucleusCore::JsonResponse.new(content: to_h, status: status)
  end
end
