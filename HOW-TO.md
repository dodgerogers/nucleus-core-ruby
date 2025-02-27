**NucleusCore::Responder** - The boundary which passes request parameters to your business logic, then renders a response.\
**NucleusCore::Policy** - Authorization objects.\
**NucleusCore::Operation** - Service implementation, executes a single use case and can rollback any side effects.\
**NucleusCore::Workflow** - Sequenced service orchestration.\
**NucleusCore::Repository** - Data access, conceals data source interaction, and returns objects the application owns.\
**NucleusCore::View** - Presentation objects, capable of rendering multiple formats.

## Expressing Business Logic

`Repositories` handle interactions with data sources (databases, API's, files, etc).

```ruby
class OrderRepository < NucleusCore::Repository
  def self.find(id)
    resp = Rest::Client.execute("https://myshop.com/orders/#{id}", :get)

    DomainModels::Order.new(id: resp[:id])
  rescue RestClient::RequestException => e
    raise NucleusCore::NotFound.new(message: e.message)
  end

  def self.destroy(id)
    Rest::Client.execute("https://myshop.com/orders/#{id}", :delete)
  rescue RestClient::CustomException => e
    raise NucleusCore::Unprocessable.new(message: e.message)
  end
end
```

`Operations` execute a single business process, attach entities and errors to the `context`, and rolls back side effects on failure. They implement two instance methods - `call` and `rollback` which are passed either a `Hash` or `Nucleus::Operation::Context` object, and are called via their class method namesakes (e.g. `FetchOrder.call(args)`, `FetchOrder.rollback(context)`).

```ruby
class FetchOrder < NucleusCore::Operation
  def call
    validate_required_args!() do |missing|
      missing.push('user_name') if context.user.name.blank?
    end

    formatted_id = "#{context.user.id}-#{context.order_id}"
    result = OrderRepository.find(formatted_id)

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

1. Create a `worker` to perform background jobs.
  ```ruby
  class Worker < NucleusCore::Worker::Adapter
    def self.call(args={})
      # delegate to sidekiq, activejob, memached, etc...
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

`Policies` have access to the accessing user, entity, and should return a boolean.

```ruby
class OrderPolicy < NucleusCore::Policy
  def can_edit_price?
    client.is_admin? && entity.user_id == client.id
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
      policy = OrderPolicy.new(req.user, req.order_id)

      policy.enforce!(:can_fulfill?)

      manager = FulfillOrder.call(id: req.order_id, user: req.user)
      context = manager.context
      
      return context if !context.success?

      return OrderView.new(order: context.order)
    end
  end
end
```