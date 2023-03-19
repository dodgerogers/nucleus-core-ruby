# Nucleus Core

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

- [Overview](#overview)
- [Components](#components)
- [Getting Started](#getting-started)
- [Implementing Business Logic](#implementing-business-logic)
- [Supported Frameworks](#supported-frameworks)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Overview

Nucleus Core defines a boundary between your business logic and the framework, so you can design your application in isolation of the framework's paradigms.

## Components

**Responder** - The boundary which handles request parameters, encapsulates your business logic, and renders a response.\
**Views** - Presentation objects which render multiple formats.\
**Operations** - Service implementation that executes one side effect.\
**Workflows** - Service orchestration which composes complex processes.

## Getting started

1. Install the gem

```ruby
$ gem install nuclueus-core
```

2. Initialize, and configure

```ruby
require "nucleus-core"

NucleusCore.configure do |config|
  config.logger = Logger.new($stdout)
  config.default_response_format = :json
  config.exceptions = {
    not_found: ActiveRecord::RecordNotFound,
    unprocessible: [ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved],
    bad_request: Apipie::ParamError,
    unauthorized: Pundit::NotAuthorizedError
  }
end
```

3. Create a class that implements the methods below to handle rendering for the framework.

```ruby
class ResponderAdapter
  # entity: Nucleus::ResponseAdapter

  def render_json(entity)
  end

  def render_xml(entity)
  end

  def render_pdf(entity)
  end

  def render_csv(entity)
  end

  def render_text(entity)
  end

  def render_nothing(entity)
  end
end
```

4. A single object made available to the business logic via the `RequestAdapter`.

```ruby
class RequestAdapter
  # args: any request parameters

  def call(args={})
    {
      format: args[:format],
      parameters: args[:params],
    }
  end
end
```

5. Define your view, and it's responses.

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

    NucleusCore::ResponseAdapter.new(format: :json, content: content)
  end

  def pdf_response
    NucleusCore::ResponseAdapter.new(format: :pdf, content: generate_pdf())
  end
end
```

6. Initialize `Nucleus::Responder` with your adapters, instantiate a request object with format and parameters, call your business logic, then return a view.

```ruby
class OrdersEndpoint
  def initialize
    @responder = Nucleus::Responder.new(
      response_adapter: ResponseAdapter.new,
      request_adapter: RequestAdapter.new
    )
    @request = {
      format: framework_req.format,
      parameters: framework_req.params
    }
  end

  def create
    @responder.execute(@request) do |req|
      context, _process = Workflows::FulfillOrder.call(context: req.parameters)

      return Views::Order.new(order: context.order) if context.success?

      return context
    end
  end
end
```

6. Then tell us about it!

### Implementing Business Logic

Use `Operations` to define single units of work, and orchestrate multiple units with `Workflows`.

```ruby
class Operations::FetchOrder < NucleusCore::Operation
  def call
    context.order = find_order(context.id)
  rescue NucleusCore::NotFound => e
    context.fail!(e.message, exception: e)
  end

  def find_order(id)
    # find implementation
  end
end
```

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
      operation: ->(context) { context.order.discount! },
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

---

## Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails).

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and we will do our best to provide a helpful answer.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
