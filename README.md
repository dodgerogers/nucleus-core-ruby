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

NucleusCore defines a boundary such that business logic can be expressed independently from the framework's paradigms.

NucleusCore is oriented around the idea that any request can be deconstructed into the following responsibilties, and has components to directly or indirectly support this:
  - Authentication
  - Authorization
  - Executing a business process
  - Accessing or mutating data
  - Rendering a response

## Components

**NucleusCore::Responder** - The boundary which passes request parameters to your business logic, then renders a response.\
**NucleusCore::Policy** - Authorization objects.\
**NucleusCore::Operation** - Service implementation, executes a single use case and can rollback any side effects.\
**NucleusCore::Workflow** - Service orchestration, composes multi-stage, divergent operations.\
**NucleusCore::Repository** - Data access, conceals the complexity of interacting with data sources from the caller.\
**NucleusCore::View** - Presentation objects, render to multiple formats.

## Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails)

## Getting started with an unsupported framework

1. Install the gem

Gemfile
```ruby
gem 'nucleus-core'
```

2. Initialize and configure

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

3. Create a class that implements the methods below.

```ruby
class ResponderAdapter
  # entity is an instance of `Nucleus::ResponseAdapter`
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

4. A `NucleusCore::RequestAdapter` object is yielded by the `Responder.execute` method by configuring a `RequestAdapter`. The properties of this object are completely up to your specification.

```ruby
class RequestAdapter
  def call(args={})
    {
      format: args[:format],
      parameters: args[:params],
      cookies: args[:cookies],
      anything: '...'
    }
  end
end
```

5. Define your view and it's responses.

```ruby
class Views::Order < NucleusCore::View
  def initialize(order, process)
    attributes = {}.tap do |attrs|
      attrs[:id] = order.id
      attrs[:price] = "$#{order.total}.00"
      attrs[:paid] = order.paid
      attrs[:created_at] = order.created_at
      attrs[:state] = process.state
    end

    super(attributes)
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
      format: request.format,
      parameters: request.params,
      cookies: request.cookies
    }
  end

  def create
    @responder.execute(@request) do |req|
      policy = OrderPolicy.new(req.user, req.order_id)

      policy.enforce!(:can_fulfill?)

      context, process = FulfillOrder.call(id: req.order_id, user: req.user)

      return context if !context.success?

      return Views::Order.new(order: context.order, process: process)
    end
  end
end
```

6. We want to support as many frameworks as possible so tell us about it!

### How to Implement Business Logic

`Policies` have access to the client, entity, and return a boolean.

```ruby
class OrderPolicy < NucleusCore::Policy
  def can_fulfill?
    client.is_admin? && entity.user_id == client.id
  end
end
```

`Repositories` handle interactions with the data source for a resource. The data access library/ORM/client is not important, all that matters is that an object that the application defines is returned.

```ruby
class OrderRepository < NucleusCore::Repository
  def self.find(id)
    execute do
      resp = Rest::Client.execute("https://myshop.com/#{id}")

      return DomainModels::Order.new(id: resp[:id])
    end
  end
end
```

`Operations` define single units of work, ideally have a single side effect, attach entities and errors to the `context`, and can rollback any side effects. They implement two instance methods - `call` and `rollback` which are passed either a `Hash` or `Nucleus::Operation::Context` object, and are called via their class method namesakes (e.g. `FetchOrder.call(args)`, `FetchOrder.rollback(context)`).

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

`Worklflows` define multi-stage, divergant proceedures, and share the same interface as `Operations`. They can be composed of `Operations` or anonymous functions, and are called as such (e.g. `FulfillOrder.call(args)`, `FulfillOrder.rollback(context)`).

```ruby
class FulfillOrder < NucleusCore::Workflow
  def define
    start_node(continue: :apply_discount?)
    register_node(
      state: :apply_discount?,
      operation: FetchOrder,
      determine_signal: ->(context) { context.order.total > 10 ? :discount : :pay },
      signals: { discount: :discount_order, pay: :take_payment }
    )
    register_node(
      state: :discount_order,
      operation: ->(context) { context.discounted = context.order.discount! },
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

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and we will do our best to provide a helpful answer.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
