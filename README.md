# Nucleus Core

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

#### Please note this package is in development, and is subject to breaking changes.

Nucleus Core is a series of components which describe, orchestrate, and execute your business logic in a way that is separate, and agnostic to the framework. The components have preordained responsibilities, are composeable, and are written in plain old Ruby, so they should work everywhere.

**Responder** - The boundary between your application, and the framework. Hands view objects from executing your use cases to the framework to render.
**Policy** - Authorization. can this process be performed?
**Operation** - Service implementation. Executes one side effect, and can undo it.
**Workflow** - Service Orchestration. Composes complex multi operation processes.
**Repository** - Data Access. Handles the complexity of interacting with a data source.
**Aggregate** - Anti Corruption. Maps data to an object the application controls.
**View** - Presentation. A view only object that can render to multiple formats.

### How Nucleus interplays with the framework for a given request

- (Framework) The server/application is issues a request
- (Framework) The parameters are validated, and formatted
- (Nucleus) A policy authorizes the request with the given params
- (Nucleus) An operation is executed with the params
  - (Nucleus) A repository fetches/mutates the data
    - (Nucleus) A aggregate is instantiated from the result
- (Nucleus) The operation returns the repository aggregate, or the context of the failure
- (Nucleus) The operation result is returned if NOT successful
- (Nucleus) A View is instantiated and returned if successful
  - (Nucleus) The view returns a response object for the given format
- (Framework) The response object is serialized to the requested format

## Getting started

```
$ gem install nuclueus-core
```

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

`controllers/orders_controller.rb`

```ruby
#
# This is the boundary between the framework and your business logic.
# The controller forwards request parameters to the Responder, Nucleus executes the operation/workflow,
# instantiates a view, and then calls the framework render the output.
class OrdersController
  include NucleusCore::Responder

  before_action do |controller|
    init_responder(response_adapter: controller)
  end

  def create
    handle_response do
      policy.enforce!(:can_write?)

      context, _process = Workflows::FulfillOrder.call(invoice_params)

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
#
# Policies exist to answer the question "can this processs be performed?
class Policies::Order < Nucleus::Policy
  def can_write?
    user.has_permissions?(...)
  end
end
```

`workflows/fulfill_order.rb`

```ruby
#
# Workflows consists of an orchestrated and repeatable pattern of operations.
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

`app/operations/\*.rb`

```ruby
#
# Operations represent one unit of business logic, or one side effect.
# They know how to perform their function well, and how to undo the side effects.
class Operations::FetchOrder < NucleusCore::Operation
  def call
    order = Repositories::Orders.find!(context.order_id)

    context.order = order
  rescue NucleusCore::NotFound => e
    context.fail!(e.message, exception: e)
  end
end

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

class Operations::SetupShipping < NucleusCore::Operation
  def call
    # ...
  end
end
```

`app/repositories/orders_repository.rb`

```ruby
#
# Here our data source is ActiveRecord, but it could be an API, raw SQL, a local file, mongo, Firebase, etc.
# The complexity, and details about "how" the data is accessed is hidden to the caller, and an objectthe application defines is returned.
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
#
# Here we are using the ActiveRecord ORM to handle the low level interactions with the data source (a database).
class Order < ActiveRecord::Base
  validates :total, :items, presence: true
  # ...
end
```

`app/aggregates/order.rb`

```ruby
#
# The aggregates takes an object returned from a data source, and adapts it to a spefici PORO
# the application defines, and controls. Also known as an "anti-corruption layer".
class Aggregates::Order < NucleusCore::Aggregate
  def initialize(order)
    super(id: order.id, total: order.total, paid: order.paid, created_at: order.created_at)
  end
end
```

`app/views/order.rb`

```ruby
#
# Presentation objects which extract properties from an aggregate (or something else) for rendering.
# They implement all the ways the object can be serialized (json, xml, csv, pdf, ...etc).
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
    NucleusCore::PdfResponse.new(content: generate_pdf)
  end

  private def generate_pdf
    # ...
  end
end
```

##### How to use in a new framework

1. Implement a class that defines the `render_<format>` methods (see `Nucleus::Responder#render_response`).
2. See `NucleusCore::Responder#init_responder` to set the class dynamically, or use the `response_adapter` config property.
3. Tell us about it!

See [!nucleus-rails](https://rubygems.org/gems/nucleus-rails) for an example.

---

- [Quick start](#quick-start)
- [Best practixes](#best-practices)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Best practices

TODO:

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
