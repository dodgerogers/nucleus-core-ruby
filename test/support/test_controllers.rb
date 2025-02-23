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
      process = nil
      context = SimpleWorkflow.call(context: req.parameters) do |manager|
        process = manager.process
      end

      return TestSimpleView.new(total: context.total, state: process.state) if context.success?

      return context
    end
  end

  def operation(params={})
    request = init_request(params)

    responder.execute(request) do |req|
      context = TallyOperation.call(req.parameters)

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
      return TestSimpleView.new(total: 0).csv
    end
  end

  def nothing(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return nil
    end
  end

  def no_format(params={})
    request = init_request(params.merge(format: nil))
    request[:format] = nil

    responder.execute(request) do |_req|
      return TestSimpleView.new(total: 0)
    end
  end

  def nothing_extended(params={})
    request = init_request(params)

    responder.execute(request) do |_req|
      return NucleusCore::View::Response.new(:nothing, headers: { "nothing" => "header" })
    end
  end

  def unsupported_html_format_requested(params={})
    request = init_request(params.merge!(format: :html))

    responder.execute(request) do |_req|
      return TestSimpleView.new(total: 0)
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
