require "securerandom"
require "ostruct"

class SimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json_response
    NucleusCore::JsonResponse.new
  end

  def xml_response
    NucleusCore::XmlResponse.new
  end

  def pdf_response
    NucleusCore::PdfResponse.new
  end

  def csv_response
    NucleusCore::CsvResponse.new
  end

  def text_response
    NucleusCore::TextResponse.new
  end
end

module MockResponseAdapter
  def render_json(entity)
    entity.class.name
  end

  def render_xml(entity)
    entity.class.name
  end

  def render_pdf(entity)
    entity.class.name
  end

  def render_csv(entity)
    entity.class.name
  end

  def render_text(entity)
    entity.class.name
  end

  def render_nothing(entity)
    entity.class.name
  end
end

# By default this controller, combined with Nucleus::Responder will use an injected
# ResponseAdapter, see `test/support/configuration` for details.
# The `MockResponseAdapter` module can be opted into by calling:
# `init_responder(request_format: , response_adapter: )` in a test.
class TestController
  include NucleusCore::Responder
  include MockResponseAdapter

  attr_accessor :params

  # For example call `init_responder` in a `before_action` to pass in the instance, or
  # use Nucleus.configuration for a static class.
  def initialize(attrs={})
    @params = attrs.fetch(:params, total: 5)
  end

  def index
    handle_response do
      policy.enforce!(:can_write?)

      context, _process = SimpleWorkflow.call(context: params)

      return SimpleView.new(total: context.total) if context.success?

      return context
    end
  end

  def show
    handle_response do
      policy.enforce!(:can_read?)

      context = TestOperation.call(params)

      return SimpleView.new(total: context.total) if context.success?

      return context
    end
  end

  private

  def policy
    TestPolicy.new(current_user)
  end

  def current_user
    OpenStruct.new(id: SecureRandom.uuid)
  end
end
