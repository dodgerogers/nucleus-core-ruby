class TestController
  attr_reader :responder

  def initialize(attrs={})
    @responder = NucleusCore::Responder.new(
      response_adapter: attrs.fetch(:response_adapter, TestResponseAdapter),
      request_adapter:  attrs.fetch(:request_adapter, TestRequestAdapter)
    )
  end

  def workflow(params={})
    request = init_request(params)

    responder.execute(request) do |req|
      manager = SimpleWorkflow.call(context: req.parameters)
      context = manager.context
      process = manager.process

      return TestSimpleView.new(total: context.total, state: process.state) if context.success?

      return context
    end
  end

  def operation(params={})
    request = init_request(params)

    responder.execute(request) do |req|
      context = TestOperation.call(req.parameters)

      return TestSimpleView.new(total: context.total) if context.success?

      return context
    end
  end

  def successful_operation_context(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return NucleusCore::Operation::Context.new
    end
  end

  def failed_operation_context(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      ctx = NucleusCore::Operation::Context.new
      ctx.fail!("something went wrong")
    rescue NucleusCore::Operation::Context::Error
      ctx
    end
  end

  def csv(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return TestSimpleView.new(total: 0).csv_response
    end
  end

  def nothing(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return nil
    end
  end

  def nothing_extended(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return NucleusCore::View::Response.new(:nothing, headers: { "nothing" => "header" })
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
