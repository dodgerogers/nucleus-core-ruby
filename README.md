# Nucleus Core

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

Nucleus Core is the boundary between your business logic, and a framework.

**Responder** - The boundary which passes request parameters from the framework to your business logic, then renders a response.\
**Operation** - Service implementation which executes one side effect, and can undo it.\
**Workflow** - Service orchestration that composes complex, multi step processes.\
**View** - Presentation objects which can render multiple formats.

## Getting started

1. Install the gem

```
$ gem install nuclueus-core
```

2. Initialize `NucleusCore`

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

3. Create a class that implements all of the `render_<format>` methods.

```ruby
class ResponderAdapter
  def render_json(entity)
    render(json: entity.content, status: entity.status)
  end

  def render_xml(entity)
    render(xml: entity.content, status: entity.status)
  end

  def render_pdf(entity)
  end
end
```

4. Create a class that implements a `call` method that formats your request params into a hash.

```ruby
class RequestAdapter
  def call(format, params, ...)
    { format: format, parameters: params, ...}
  end
end
```

4. Implement, and orchestrate your business logic using Operations, and Workflows.

`workflows/fulfill_order.rb`

```ruby
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
      operation: ->(context) { context.paid = context.order.pay! },
      signals: { continue: :completed }
    )
    register_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end
```

`operations/fetch_order.rb`

```ruby
class Operations::FetchOrder < NucleusCore::Operation
  def call
    # Data access is up to you.
    context.order = find_order(context.id)
  rescue NucleusCore::NotFound => e
    context.fail!(e.message, exception: e)
  end
end
```

`operations/apply_order_discount.rb`

```ruby
class Operations::ApplyOrderDiscount < NucleusCore::Operation
  def call
    # Persistance is up to you.
    order = update_order(context.order, discount: 0.25)

    context.order = order
  rescue NucleusCore::NotFound, NucleusCore::Unprocessable => e
    context.fail!(e.message, exception: e)
  end
end
```

5. Define your views, and responses.

`views/order.rb`

```ruby
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

4. Then initialize the responder, and compose your business logic in the responder#execute method.

`controllers/orders_controller.rb`

```ruby
class OrdersController
  before_action do
    @responder = Nucleus::Responder.new(
      response_adapter: ResponseAdapter,
      request_adapter: RequestAdapter
    )
  end

  def create
    @responder.execute(request) do |req|
      context, _process = Workflows::FulfillOrder.call(context: req.parameters)

      return Views::Order.new(order: context.order) if context.success?

      return context
    end
  end
end
```

5. Then tell us about it!

### Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails)

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
