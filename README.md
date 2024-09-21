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
  # The response_types configuration allows specifying different formats for API responses.
  # Each key represents a format (e.g., :csv, :pdf, :json, etc...), and the associated value is a hash
  # defining attributes for rendering that format. Common attributes include disposition (how
  # the file is served, e.g., inline or as an attachment), type (MIME type), and filename
  # (suggested name for attachments). This setup makes it easy to support multiple content types
  # in API responses, handling various client preferences like JSON, XML, or file downloads.
  config.response_formats = {
    csv: { disposition: "attachment", type: "text/csv; charset=UTF-8;", filename: "response.csv" },
    pdf: { disposition: "inline", type: "application/pdf", filename: "response.pdf" },
    json: { type: "application/json", format: :json },
    xml: { type: "application/xml", format: :xml },
    html: { type: "text/html", format: :html },
    text: { type: "text/plain", format: :text },
    nothing: { content: nil, type: "text/html; charset=utf-8", format: :nothing }
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
