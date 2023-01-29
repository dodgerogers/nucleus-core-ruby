# Nucleus

[![Gem Version](https://badge.fury.io/rb/nucleus-framework.svg)](https://rubygems.org/gems/nucleus-framework)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-framework/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-framework/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus)

Nucleus is an optionated framework of components with preordained respoonsibilities that enable the expression of business logic agnostic to the framework.

The following classes are provided so business cases can be orchestrated, expressed consistently, and tested in isolation.

- Policy (Authorization) - can the user perform this process?
- Operation (Service class) - Execute a single unit of business logic (ScheduleAppointment, CancelOrder, UpdateAddress)
- Workflow (Service orchestration) - Orchestrate a complex business workflow using Operations (ApproveLoan, TakePayment, CancelFulfillments)
- View (Presentation) - A presentation object to be adapted to multiple output formats (OrderView, CustomerView)
- Repository (Data access) - Handles interactions with a data source where and however it is stored, such that callers are unaware to the implementation details, but are returned an object the application owns and defines (see Aggregates) below. External data sources could be: an external API, ActiveRecord, a file, etc...
- Aggregate (Domain/business Object) - An object returned from repositories such that changes to the external data schema do not flow into the app unknowingly.

Below is a trivial example of what using Nucleus would look like using Rails:

```ruby
# controllers/calculate_amount.rb
class PaymentsController
  def create
    Nucleus::Responder.handle_response do
      Policy.new(current_user).enforce!(:can_write?)

      invoice_params = params.slice(:cart_id)
      context, _process = HandleCheckoutWorkflow.call(invoice_params)

      if context.success?
        return PaymentView.new(cart: context.cart, paid: context.paid)
      else
        return context
      end
    end
  end
end

# workflows/handle_checkout_workflow.rb
class HandleCheckoutWorkflow < Nucleus::Workflow
  def define
    start_node(continue: :calculate_amount)
    register_node(
      state: :calculate_amount,
      operation: FetchShoppingCart
      determine_signal: ->(context) { context.price > 10 ? :discount : :pay }
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

# operations/calculate_amount.rb
class FetchShoppingCart < Nucleus::Operation
  def call
    cart = ShoppingCartRepository.find(context.cart_id)

    context.cart = cart
  rescue Nucleus::NotFound => e
    context.fail!(e.message, exception: e)
  end
end

# repositories/shopping_cart_repository.rb
class ShoppingCartRepository < Nucleus::Repository
  def self.find(cart_id)
    cart = ShoppingCart.find(cart_id)

    return ShoppingCart::Aggregate.new(cart)
  rescue ActiveRecord::RecordNotFound => e
    raise Nucleus::NotFound, e.message
  end

  def self.discount(cart_id, percentage)
    cart = find(cart_id, percentage=0.5)

    cart.update!(price: cart.price * percentage, paid: true)

    return ShoppingCart::Aggregate.new(cart)
  rescue Nucleus::NotFound => e
    raise e
  end
end

# aggregates/shopping_cart.rb
class ShoppingCart::Aggregate < Nucleus::Aggregate
  def initialize(cart)
    super(id: cart.id, price: cart.price, paid: cart.paid, created_at: cart.created_at)
  end
end

# operations/apply_discount.rb
class ApplyDiscountToShoppingCart < Nucleus::Operation
  def call
    cart = ShoppingCartRepository.discount(context.cart_id, 0.75)

    context.cart
  rescue Nucleus::NotFound => e
    context.fail!(e.message, exception: e)
  end
end

# views/payments_view.rb
class Nucleus::PaymentView < Nucleus::View
  def initialize(cart)
    super(price: cart.price, paid: cart.paid, created_at: cart.created_at)
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
