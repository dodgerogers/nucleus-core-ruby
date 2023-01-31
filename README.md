# Nucleus

[![Gem Version](https://badge.fury.io/rb/nucleus-framework.svg)](https://rubygems.org/gems/nucleus-framework)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-framework/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-framework/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus)

Nucleus is a framework to express and orchestrate business logic in a way that is agnostic to the framework. 

This gem is still very much in alpha, and a `nucleus-rails` gem will be created to handle the adaptation of Nucleus::View objects to the rails rendering methods.

Here are all the classes Nucleus exposes. They have preordained responsibilities, can be composed together, and tested simply.

- Policy (Authorization) - Can this user perform `X`?
- Operation (Services) - Execute a single unit of business logic. or side effect (ScheduleAppointment, CancelOrder, UpdateAddress).
- Workflow (Service Orchestration) - Excecute multiple units of work, and side effects (ApproveLoan, TakePayment, CancelFulfillments).
- View (Presentation) - A presentation object which can render to multiple formats.
- Repository (Data access) - Interacts with data sources to hide the implementation details to callers, and return Aggregates. Data sources could be an API, ActiveRecord, SQL, a local file, etc.
- Aggregate (Domain/business Object) - Maps data from the data source to an object the aplication defines, known as an anti corruption layer.

Below is an example using Nucleus with Rails:

```ruby
# controllers/payments_controller.rb
class PaymentsController < ApplicationController
  def create
    Nucleus::Responder.handle_response do
      policy.enforce!(:can_write?)

      context, _process = HandleCheckoutWorkflow.call(invoice_params)

      return context if !context.success?

      return PaymentView.new(cart: context.cart, paid: context.paid)
    end
  end

  private

  def policy
    Policy.new(current_user)
  end

  def invoice_params
    params.slice(:cart_id)
  end
end

# workflows/handle_checkout_workflow.rb
class HandleCheckoutWorkflow < Nucleus::Workflow
  def define
    start_node(continue: :calculate_amount)
    register_node(
      state: :calculate_amount,
      operation: FetchShoppingCart,
      determine_signal: ->(context) { context.cart.total > 10 ? :discount : :pay },
      signals: { discount: :apply_discount, pay: :take_payment }
    )
    register_node(
      state: :apply_discount,
      operation: ApplyDiscountToShoppingCart,
      signals: { continue: :take_payment }
    )
    register_node(
      state: :take_payment,
      operation: ->(context) { context.paid = context.cart.paid },
      determine_signal: ->(_) { :completed }
    )
    register_node(
      state: :completed,
      determine_signal: ->(_) { :wait }
    )
  end
end

# app/operations/fetch_shopping_cart.rb
class FetchShoppingCart < Nucleus::Operation
  def call
    cart = ShoppingCartRepository.find(context.cart_id)

    context.cart = cart
  rescue Nucleus::NotFound => e
    context.fail!(e.message, exception: e)
  end
end

# app/repositories/shopping_cart_repository.rb
class ShoppingCartRepository < Nucleus::Repository
  def self.find(cart_id)
    cart = ShoppingCart.find(cart_id)

    return ShoppingCart::Aggregate.new(cart)
  rescue ActiveRecord::RecordNotFound => e
    raise Nucleus::NotFound, e.message
  end

  def self.discount(cart_id, percentage)
    cart = find(cart_id, percentage=0.5)

    cart.update!(total: cart.total * percentage, paid: true)

    return ShoppingCart::Aggregate.new(cart)
  rescue Nucleus::NotFound => e
    raise e
  end
end

class ShoppingCart < ActiveRecord::Base
  # ...
end

# app/aggregates/shopping_cart.rb
class ShoppingCart::Aggregate < Nucleus::Aggregate
  def initialize(cart)
    super(id: cart.id, total: cart.total, paid: cart.paid, created_at: cart.created_at)
  end
end

# app/operations/apply_discount_to_shopping_cart.rb
class ApplyDiscountToShoppingCart < Nucleus::Operation
  def call
    cart = ShoppingCartRepository.discount(context.cart_id, 0.75)

    context.cart
  rescue Nucleus::NotFound => e
    context.fail!(e.message, exception: e)
  end
end

# app/views/payments_view.rb
class Nucleus::PaymentView < Nucleus::View
  def initialize(cart)
    super(total: "$#{cart.total}", paid: cart.paid, created_at: cart.created_at)
  end

  def json_response
    content = {
      payment: {
        price: price,
        paid: paid,
        created_at: created_at,
        signature: SecureRandom.hex
      }
    }

    Nucleus::JsonResponse.new(content: content)
  end

  def pdf_response
    pdf_string = generate_pdf_string(price, paid)

    Nucleus::PdfResponse.new(content: pdf_string)
  end

  private def generate_pdf_string(price, paid)
    # pdf string genration...
  end
end
```

---

- [Quick start](#quick-start)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Quick start

```
$ gem install nucleus-framework
```

```ruby
require "nucleus-framework"
```

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
