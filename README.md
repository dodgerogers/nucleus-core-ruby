# Nucleus

[![Gem Version](https://badge.fury.io/rb/nucleus.svg)](https://rubygems.org/gems/nucleus)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus)

Nucleus is an optionated framework of paradigms, and components that aim to express the business logic of your application without being tied to your framework.

Below is a trivial example of what using Nucleus would look like using Rails:

```
class InvoiceController
  def index
    Nucleus::Responder.handle_response do
      Policy.new(current_user).enforce!(:can_write?)

      invoice_params = params.slice(:price)
      context, _process = HandlePaymentWorkflow.call(invoice_params)

      return PaymentView.new(price: context.price, paid: context.paid) if context.success?
      return context
    end
  end
end

class HandlePaymentWorkflow < Nucleus::Workflow
  def define
    start_node(continue: :calculate_amount)
    register_node(
      state: :calculate_amount,
      operation: ->(context) { context.price = rand(1..12) }
      determine_signal: ->(context) { context.price > 10 ? :discount : :pay }
      signals: { discount: :apply_discount, pay: :take_payment }
    )
    register_node(
      state: :apply_discount,
      operation: ->(context) { context.price = context.price * 0.75 },
      signals: { continue: :take_payment }
    )
    register_node(
      state: :take_payment,
      operation: ->(context) { context.paid = true },
      determine_signal: ->(_) { :wait }
    )
  end
end

class Nucleus::PaymentView < Nucleus::View
  def initialize(attrs={})
    super(price: attrs[:price], paid: attrs[:paid])
  end

  def json_response
    content = { { payment: { price: price, paid: paid } } }
    Nucleus::JsonResponse.new(content: content)
  end

  def pdf_response
    pdf_string = generate_pdf_string(price, paid)
    Nucleus::PdfResponse.new(content: pdf_string)
  end
end
```

Nucleus provides the following classes with their respective resonsibilities, so complex business cases can be orchestrated together, expressed consistently, and tested agnostic to setting up framework concerns.

- Policy (Authorization) - can user `X` do `Y`?
- Operation - Execute a single unit of business logic (ScheduleAppointment, CancelOrder)
- Workflow - Orchestrate a complex business workflow using Operations (ApproveLoan, TakePayment)
- View - A presentation object which can be adapted to multiple formats (OrderView, CustomerView)
- Repository - handles nteractions with a data source wherevver it is sourced, such that callers are unaware to the implementation details, but are returned an object the application owns and defines (see Aggregates) below. External data sources could be: ActiveRecord, an external API, a local file, etc
- Aggregate - An anti corruption object which should be returned from repositories, such that external changes to the data source of the repository do not flow into the app unknowingly.

---

- [Quick start](#quick-start)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Quick start

```
$ gem install nucleus-dsl
```

```ruby
require "nucleus-dsl"
```

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus/issues/new) and I will do my best to provide a helpful answer. Happy hacking!

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
