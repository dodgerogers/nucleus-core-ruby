# Nucleus Core

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

#### Please note this package is in development, and is subject to breaking changes until 1.0.0

Nucleus Core is a series of components which describe, orchestrate, and execute your business logic in a way that is separate, and agnostic to the framework. The components have preordained responsibilities, and are written in plain old Ruby so they should work everywhere.

**Responder** - The boundary between your application, and the framework. Handles exceptions, and passes view objects to the framework to render.\
**Policy** - Authorization. can this process be performed?\
**Operation** - Service implementation. Executes one side effect, and can undo it.\
**Workflow** - Service Orchestration. Composes complex, multi operation processes.\
**Repository** - Data Access. Handles, and hides the complexity of interacting with a data source.\
**Aggregate** - Anti Corruption. Maps data to an object the application controls.\
**View** - Presentation. A view only object that can render to multiple formats.\

## Getting started

1. Install the gem

```
$ gem install nuclueus-core
```

2. Initialize, and configure NucleusCore

`initializers/nucleus_core.rb`

```ruby
require "nucleus-core"

NucleusCore.configure do |config|
  config.logger = Rails.logger
  config.exceptions = {
    not_found: ActiveRecord::RecordNotFound,
    unprocessible: [ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved, ActiveRecord::StatementInvalid],
    bad_request: Apipie::ParamError,
    unauthorized: Pundit::NotAuthorizedError
  }
end
```

3. Define a response adapter (for unsupported frameworks) that takes Nucleus::ResponseAdapter objects,and renders them to the specified format.
4. Define your business logic using Policies, Operations, Workflows, Repositories, and Views, then wrap your components in the `handle_response` method to render the output.

## Example

`controllers/orders_controller.rb`

```ruby
# The Responder is the boundary between the framework and your business logic.
# Execute your business logic then return a view object.
class OrdersController
  include NucleusCore::Responder

  before_action do |controller|
    # Initialize a response adapter that implements the required render methods.
    # See `Responder#render_response` for details.
    init_responder(response_adapter: controller)
  end

  def create
    handle_response do
      policy.enforce!(:can_write?)

      context, _process = Workflows::FulfillOrder.call(context: invoice_params)

      return context if !context.success?

      return Views::Order.new(order: context.order, paid: context.paid)
    end
  end

  private

  def policy
    Policies::Order.new(current_user)
  end

  def invoice_params
    params.slice(:order_id)
  end
end
```

`policies/order.rb`

```ruby
# Policies simply answer the question "can I perform this process?"
class Policies::Order < Nucleus::Policy
  def can_write?
    user.has_permissions?(...)
  end
end
```

`workflows/fulfill_order.rb`

```ruby
# Workflows consists of an orchestrated, and repeatable pattern of operations.
class Workflows::FulfillOrder < NucleusCore::Workflow
  def define
    start_node(continue: :apply_discount?)
    register_node(
      state: :apply_discount?,
      operation: Operations::FetchOrder,
      determine_signal: ->(context) { context.order.total > 10 ? :discount : :pay },
      signals: { discount: :apply_discount, pay: :take_payment }
    )
    register_node(
      state: :apply_discount,
      operation: Operations::ApplyOrderDiscount,
      signals: { continue: :take_payment }
    )
    register_node(
      state: :take_payment,
      operation: ->(context) { context.paid = context.order.paid },
      determine_signal: ->(_) { :ship },
      signals: { ship: :organize_shipping }
    )
    register_node(
      state: :organize_shipping,
      operation: Operations::SetupShipping,
      signals: { continue: :completed }
    )
    register_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end
```

`app/operations/fetch_order.rb`

```ruby
# Operations represent one unit of business logic, or one side effect.
# They know how to perform their function well, and undo any side effects.
class Operations::FetchOrder < NucleusCore::Operation
  def call
    order = Repositories::Orders.find!(context.order_id)

    context.order = order
  rescue NucleusCore::NotFound => e
    context.fail!(e.message, exception: e)
  end
end
```

`app/operations/apply_order_discount.rb`

```ruby
class Operations::ApplyOrderDiscount < NucleusCore::Operation
  def call
    order = Repositories::Orders.update!(context.order_id, discount: 0.75)

    context.order
    context.order_changes = order.changes
  rescue NucleusCore::NotFound, NucleusCore::Unprocessable => e
    context.fail!(e.message, exception: e)
  end

  def rollback
    return if !context.order_changes

    Repositories::Orders.update!(context.order_id, context.order_changes)
  end
end
```

`app/operations/setup_shipping.rb`

```ruby
class Operations::SetupShipping < NucleusCore::Operation
  def call # ...
  end
end
```

`app/repositories/orders_repository.rb`

```ruby
# We're interacting with our data source (a database) using ActiveRecord, but it could be an API,
# a local file, Firebase, etc. The complexity, and details of "how" the data is accessed is
# hidden to the caller, and an object the application owns, and defines is returned.
class Repositories::Orders < NucleusCore::Repository
  def self.find!(order_id)
    cart = Order.find(order_id)

    return Aggregates::Order.new(cart)
  rescue ActiveRecord::RecordNotFound => e
    raise NucleusCore::NotFound, e.message
  end

  def self.update!(order_id, attrs={})
    cart = find(order_id)

    attrs.tap do |a|
      attrs[:total] = cart.total * attrs.delete(:discount) if attrs[:discount]
      attrs[:paid] = true
    end

    cart.assign_attributes(attrs)
    cart.save!

    return Aggregates::Order.new(cart)
  rescue NucleusCore::NotFound => e
    raise e
  rescue ActiveRecord::RecordNotSaved => e
    raise Nucleus::Unprocessable, e.message
  end
end
```

`app/models/order.rb`

```ruby
# Here we are using the ActiveRecord ORM to handle the low level interactions with the data source (a database).
class Order < ActiveRecord::Base
  validates :total, :items, presence: true
  # ...
end
```

`app/aggregates/order.rb`

```ruby
# The aggregate takes an object from a data source, and adapts it to a PORO the application controls.
class Aggregates::Order < NucleusCore::Aggregate
  def initialize(order)
    super(id: order.id, total: order.total, paid: order.paid, created_at: order.created_at)
  end
end
```

`app/views/order.rb`

```ruby
# Presentation objects that extract properties from an aggregate for rendering only.
# They also implement the ways the object can be serialized (json, xml, csv, pdf, ...etc).
class Views::Order < NucleusCore::View
  def initialize(order)
    attrs = {
      id: order.id,
      price: "$#{order.total}",
      paid: order.paid,
      created_at: order.created_at
    }
    super(attrs)
  end

  def json_response
    content = {
      payment: {
        id: id,
        price: price,
        paid: paid,
        created_at: created_at,
        signature: SecureRandom.hex
      }
    }

    NucleusCore::JsonResponse.new(content: content)
  end

  def pdf_response
    NucleusCore::PdfResponse.new(content: generate_pdf(id, price, paid))
  end
end
```

##### Wanting to use Nucleus Core in an unspported Ruby framework?

1. Implement a class that defines the `render_<format>` methods (see `Nucleus::Responder#render_response`).
2. See `NucleusCore::Responder#init_responder` to set the class dynamically, or use the `response_adapter` config property.
3. Then tell us about it! We want to cover as many frameworks as possible.

See [!nucleus-rails](https://rubygems.org/gems/nucleus-rails) for an example.

---

- [Quick start](#quick-start)
- [Best practixes](#best-practices)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Best practices

- Favour composeablility over coupling. In other words, no not use policies, or views in operations/workflows to keep access, and rendering outside of your business cases.

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and we will do our best to provide a helpful answer.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
