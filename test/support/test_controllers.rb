require "securerandom"
require "ostruct"

# By default this controller NucleusCore::Responder will use an injected
# ResponseAdapter, see `test/support/configuration` for details.
class TestController
  attr_reader :responder

  def initialize(attrs={})
    @responder = NucleusCore::Responder.new(
      response_adapter: attrs.fetch(:response_adapter, TestResponseAdapter),
      request_adapter:  attrs.fetch(:request_adapter, TestRequestAdapter)
    )
  end

  def index(params={})
    request = init_request(params)

    responder.execute(request) do |req|
      context, _process = SimpleWorkflow.call(context: req.parameters)

      return TestSimpleView.new(total: context.total) if context.success?

      return context
    end
  end

  def show(params={})
    request = init_request(params)

    responder.execute(request) do |req|
      context = TestOperation.call(req.parameters)

      return TestSimpleView.new(total: context.total) if context.success?

      return context
    end
  end

  def update(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return TestSimpleView.new(total: 0).csv_response
    end
  end

  private

  def init_request(params={})
    {
      format: params.fetch(:format, :json),
      headers: params.fetch(:headers, {}),
      parameters: params.fetch(:params, { total: 5 })
    }
  end
end
