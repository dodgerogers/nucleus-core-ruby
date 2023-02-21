# Nucleus Core

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

Nucleus Core is the boundary between your business logic, and the framework.

**Responder** - The boundary. Handles passing requests to your your business logic, and renders responses.\
**Operation** - Service implementation. Executes one side effect, and can undo it.\
**Workflow** - Service Orchestration. Composes complex, multi step, potentially diverging processes.\
**View** - Presentation. A view only object for rendering multiple formats.

## Getting started

1. Install the gem

```
$ gem install nuclueus-core
```

2. Initialize Nucleus

`initializers/nucleus_core.rb`

```ruby
require "nucleus-core"

NucleusCore.configure do |config|
  config.logger = Rails.logger
  config.default_response_format = :json
  config.exceptions = {
    not_found: ActiveRecord::RecordNotFound,
    unprocessible: [ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved],
    bad_request: Apipie::ParamError,
    unauthorized: Pundit::NotAuthorizedError
  }
end
```

3. Create a class/instance that implements the `render_<format>` methods, and call `Nucleus::Responder#init_responder(response_adapter: nil, request_format: nil)` to set the class/instance.
4. Then tell us about it!

### Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails)

## Example

`controllers/orders_controller.rb`

```ruby
# The Responder is the boundary between the framework and your business logic.
# Execute your business logic then return a view object.
class OrdersController
  include NucleusCore::Responder

  before_action do |_controller|
    # Initialize a response adapter that implements the required render methods.
    # See `Responder#render_response` for details.
    init_responder(
      response_adapter: ResponseAdapter,
      request_adapter: RequestAdapter)
  end

  def create
    handle_response(request) do
      policy.enforce!(:can_write?)

      context, _process = Workflows::FulfillOrder.call(context: params)

      return Views::Order.new(order: context.order) if context.success?

      return context
    end
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
      signals: { discount: :discount_order, pay: :take_payment }
    )
    register_node(
      state: :discount_order,
      operation: Operations::ApplyOrderDiscount,
      signals: { continue: :take_payment }
    )
    register_node(
      state: :take_payment,
      operation: ->(context) { context.paid = context.order.paid },
      signals: { continue: :organize_shipping }
    )
    register_node(
      state: :organize_shipping,
      operation: Operations::ShipOrder,
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
    context.order = find_order()
  rescue NucleusCore::NotFound => e
    context.fail!(e.message, exception: e)
  end
end
```

`app/operations/apply_order_discount.rb`

```ruby
class Operations::ApplyOrderDiscount < NucleusCore::Operation
  def call
    order = update_order(context.order)

    context.order = order
  rescue NucleusCore::NotFound, NucleusCore::Unprocessable => e
    context.fail!(e.message, exception: e)
  end
end
```

`app/operations/setup_shipping.rb`

```ruby
class Operations::ShipOrder < NucleusCore::Operation
  def call
  end
end
```

`app/views/order.rb`

```ruby
# Presentation objects that extract properties from an aggregate for rendering only.
# They also implement the ways the object can be serialized (json, xml, csv, pdf, ...etc).
class Views::Order < NucleusCore::View
  def initialize(order)
    super(id: order.id, price: "$#{order.total}", paid: order.paid, created_at: order.created_at)
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
