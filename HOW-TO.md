**NucleusCore::Responder** - The boundary which passes request parameters to your business logic, then renders a response.\
**NucleusCore::Operation** - Service implementation, executes a single use case and can rollback any side effects.\
**NucleusCore::Workflow** - Sequenced service orchestration.\
**NucleusCore::View** - Presentation objects, capable of rendering multiple formats.

## Expressing Business Logic

`Operations` execute a single business process, attach entities and errors to the `context`, and rolls back side effects on failure. They implement two instance methods - `call` and `rollback` which are passed either a `Hash` or `Nucleus::Operation::Context` object, and are called via their class method namesakes (e.g. `FetchOrder.call(args)`, `FetchOrder.rollback(context)`).

```ruby
class FetchOrder < NucleusCore::Operation
  def call
    validate_required_args!() do |missing|
      missing.push('user_name') if context.user.name.blank?
    end

    formatted_id = "#{context.user.id}-#{context.order_id}"
    result = Order.find(formatted_id)

    if result.exception
      message = "Couldn't find order with ID #{formatted_id}"
      context.fail!(message, exception: result.exception)
    end

    order = result.entity

    log_order_was_accessed(order)

    context.order = order
  rescue NucleusCore::BaseException => e
    context.fail!(e.message, exception: e)
  end

  def required_args
    [:id, :user].freeze
  end

  def rollback
    delete_order_access_log(context.order) if context.order
  end
end
```

`Worklflows` define multi-step proceedures, are composed of operations or lambas/procs, and return a workflow manager object.

```ruby
class FulfillOrder < NucleusCore::Workflow
  def define
    start_node(continue: :apply_discount?)
    add_node(
      state: :apply_discount?,
      operation: FetchOrder,
      determine_signal: ->(context) { context.order.total > 10 ? :discount : :pay },
      signals: { discount: :discount_order, pay: :take_payment }
    )
    add_node(
      state: :discount_order,
      operation: ->(context) { context.discounted = context.order.discount! },
      signals: { continue: :take_payment }
    )
    add_node(
      state: :take_payment,
      operation: ProcessOrderPayment,
      signals: { continue: :completed }
    )
    add_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end
```

6. Define views and the formats they render to.

```ruby
class OrderView < NucleusCore::View
  def initialize(order)
    attributes = {}.tap do |attrs|
      attrs[:id] = order.id
      attrs[:state] = process.state
      attrs[:paid] = order.paid
      attrs[:created_at] = order.created_at
    end

    super(attributes)
  end

  def json
    build_response(content: to_h)
  end

  def csv
    build_response(content: generat_csv(self))
  end

  def pdf
    build_response(content: generat_pdf(self))
  end
end
```

7. Then compose it all together.

```ruby
class OrdersEndpoint
  def initialize
    @responder = Nucleus::Responder.new(
      response_adapter: ResponseAdapter,
      request_adapter: RequestAdapter
    )
    @request = {
      format: request.format,
      parameters: request.params,
      cookies: request.cookies
    }
  end

  def create
    @responder.execute(@request) do |req|
      manager = FulfillOrder.call(id: req.order_id, user: req.user)
      context = manager.context
      
      return context if !context.success?

      return OrderView.new(order: context.order)
    end
  end
end
```