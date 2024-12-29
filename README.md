# Nucleus Core Ruby

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core-ruby/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core-ruby?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

- [Overview](#overview)
- [Supported Frameworks](#supported-frameworks)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Contribution guide](#contribution-guide)

## Overview

Nucleus Core provides a framework-agnostic foundation for encapsulating domain logic enabling seamless integration across various platforms and mediums.

It prescribes that a request is broken down as follows:

#### 1. Device
- Receives request  

---

#### 2. Framework
- Formats request parameters and passes them to a receiver  

---

#### 3. Nucleus
- Authenticate & Authorize (if applicable)
- Execute an operation or workflow  
- Interact with data via a repository  
- Return a view object  

---

#### 4. Framework
- Renders the view object in the requested format  

---

#### 5. Device
- Displays the output to the medium it serves  

---

## Getting started

1. Install the gem

```ruby
gem install 'nucleus-core'
```

2. Initialize and configure

```ruby
require "nucleus-core"

NucleusCore.configure do |config|
  config.logger = Logger.new($stdout)
  config.default_response_format = :json # defaults to :json
  # The request_exceptions attribute allows you to define custom exception handling for different
  # HTTP error types. The keys are standard error names like :bad_request, :unauthorized, and :not_found,
  # and the values are the exception classes or errors you want to handle for each case.
  config.request_exceptions = {
    not_found: RecordNotFound,
    unprocessible: [RecordInvalid, RecordNotSaved],
    bad_request: ArgumentError,
    forbidden: NotPermittedError,
    unauthorized: UnAuthenticatedError
  }
end
```

3. Refer to the [how to](HOW-TO.md) section for guidance on writing business logic.

## Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails)

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and we will do our best to provide a helpful answer, and if you'd like to support the mission [donate](https://paypal.me/Dodgerogers)

## License

The gem is available under the terms of the [proprietary software license](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
