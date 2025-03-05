# Nucleus Core Ruby

[![Gem Version](https://badge.fury.io/rb/nucleus-core.svg)](https://rubygems.org/gems/nucleus-core)
[![Circle](https://circleci.com/gh/dodgerogers/nucleus-core-ruby/tree/main.svg?style=shield)](https://app.circleci.com/pipelines/github/dodgerogers/nucleus-core-ruby?branch=main)
[![Code Climate](https://codeclimate.com/github/dodgerogers/nucleus-core/badges/gpa.svg)](https://codeclimate.com/github/dodgerogers/nucleus-core)

- [Overview](#overview)
- [Supported Frameworks](#supported-frameworks)
- [Support](#support)
- [License](#license)
- [Code of conduct](#code-of-conduct)
- [Final Thoughts](#final-thoughts)

## Overview

Modern applications often blur the line between business logic and framework concerns, making them harder to maintain, test, and extend.

Nucleus Core solves this by providing a framework-agnostic foundation for structuring business logic. This means:
✅ Your logic remains portable, working seamlessly across different frameworks.
✅ Testing becomes easier, with no dependency on a specific web stack.
✅ Your codebase is more maintainable, with clear separation of concerns.

Instead of letting the framework dictate how your business logic runs, Nucleus Core defines a structured flow that keeps your application modular and adaptable.

---

## 🔍 **How Nucleus Core Works**  

Every request—whether from a web app, an API call, a mobile device, or a CLI—follows a **structured five-step process** to **ensure clarity, modularity, and adaptability** across different systems.  

### **1️⃣ Device (User or External System Initiates a Request)**  
📡 A request is made—this could be:  
- A **user clicking a button** on a website.  
- A **mobile app fetching data** from an API.  
- A **system sending a webhook** to another service.  
- A **CLI command requesting an operation**.  

At this stage, the **raw request is created** and sent to the system.  

---

### **2️⃣ Framework (Receives & Parses the Request)**  
🔍 The framework (e.g., Rails, Sinatra, a custom API gateway, or any other system) **processes the request**:  
- **Extracts** relevant parameters (e.g., URL params, headers, body data).  
- **Applies middleware** (e.g., logging, request validation).  
- **Passes the formatted request** to the business logic layer.  

---

### **3️⃣ Nucleus Core (Processes the Business Logic)**  
🛠 **The core engine of your application executes the request**:  
- **Authenticates & authorizes** (if required).  
- **Executes an operation or workflow** (e.g., fetching data, updating a record, triggering an event).  
- **Generates a structured response** in the form of a **view object**, ensuring consistent output.  

This is where the real **business logic happens**—separated from any framework concerns.  

---

### **4️⃣ Framework (Formats & Renders the Response)**  
🎨 The framework **receives the structured response** from Nucleus Core and:  
- **Formats it** according to the requested output (e.g., JSON, XML, HTML, or plaintext).  
- **Applies additional transformations** (e.g., adding pagination metadata, compressing data).  
- **Sends the final formatted response** back to the requesting device.  

---

### **5️⃣ Device (Receives & Displays the Response)**  
📲 The **response is rendered in an appropriate format**:  
- A **web browser displays an HTML page**.  
- A **mobile app updates its UI** with new data.  
- A **server processes the response** from an API call.  
- A **CLI prints the result** to the terminal.  

---

### **🔹 Why This Matters**  
By structuring requests in this way, **your business logic stays clean, portable, and reusable**, while frameworks handle only the **transport and rendering of data**.  

This **clear separation of concerns** allows Nucleus Core to:  
✅ Work **seamlessly across different frameworks and platforms**.  
✅ Keep business logic **independent of the transport layer**.  
✅ Ensure **predictable, structured, and testable** responses.

---

## Getting started

1. Install the gem

```ruby
gem install 'nucleus-core'
```

2. Initialize `NucleusCore`

```ruby
require "nucleus-core"

NucleusCore.configure do |config|
  config.logger = Logger.new($stdout)
  config.default_response_format = :xml # defaults to :json
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

## Final thoughts

Final Thoughts
By using Nucleus Core, you're making a deliberate choice to:
✅ Write cleaner, more maintainable code
✅ Keep business logic portable across frameworks
✅ Reduce duplication and improve testability

Break free from framework-specific constraints—start using NucleusCore today! 🚀
