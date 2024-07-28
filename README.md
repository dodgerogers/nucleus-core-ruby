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

Nucleus-Core-Ruby provides a structure to separate your business logic from your framework, streamlining request handling as follows:

**Device**
* Receives request
-----------------------------------------------------------------------------------
**Framework**
* Formats request parameters and passes them to a receiver
-----------------------------------------------------------------------------------
**Business Logic**
* Authenticate
* Authorize
* Execute Operation/Workflow
* Interact with data source via a Repository
* Return view object given Operation/Workfow result
-----------------------------------------------------------------------------------
**Framework**
* Renders view object to the requested format
-----------------------------------------------------------------------------------
**Device**
* Device displays output to the medium it serves

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
  config.default_response_format = :json
  config.request_exceptions = {
    not_found: RecordNotFound,
    unprocessible: [RecordInvalid, RecordNotSaved],
    bad_request: ArgumentError,
    forbidden: NotPermittedError,
    unauthorized: UnAuthenticatedError
  }
end
```

3. Refer to the 'How-To' section for guidance on expressing your business logic.

## Supported Frameworks

- [nucleus-rails](https://rubygems.org/gems/nucleus-rails)

## Support

If you want to report a bug, or have ideas, feedback or questions about the gem, [let me know via GitHub issues](https://github.com/dodgerogers/nucleus_core/issues/new) and we will do our best to provide a helpful answer.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Code of conduct

Everyone interacting in this project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Contribution guide

Pull requests are welcome!
