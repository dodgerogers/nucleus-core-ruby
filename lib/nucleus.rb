require "ostruct"
require "nucleus/exceptions"
require "json"
require "set"

Dir[File.join(__dir__, "nucleus", "extensions", "*.rb")].sort.each { |file| require file }

module Nucleus
  autoload :CLI, "nucleus/cli"
  autoload :VERSION, "nucleus/version"
  autoload :BasicObject, "nucleus/basic_object"
  autoload :View, "nucleus/views/view"
  autoload :ErrorView, "nucleus/views/error_view"
  autoload :ResponseAdapter, "nucleus/response_adapter"
  autoload :Aggregate, "nucleus/aggregate"
  autoload :Policy, "nucleus/policy"
  autoload :Operation, "nucleus/operation"
  autoload :Workflow, "nucleus/workflow"
  autoload :Responder, "nucleus/responder"

  class Configuration
    attr_accessor :logger
    attr_reader :responder

    EXCEPTIONS = %i[not_found bad_request unauthorized unprocessable server_error].freeze
    ADAPTER_METHODS = %i[render_json render_xml render_text render_pdf render_csv render_nothing].freeze

    def initialize
      @responder = objectify(adapter: nil, exceptions: objectify(exception_defaults))
      @logger = nil
    end

    def responder=(args={})
      exceptions = objectify(
        args
          .fetch(:exceptions, exception_defaults)
          .slice(*exception_defaults.keys)
          .reduce({}) do |acc, (key, value)|
            acc.merge(key => Array.wrap(value))
          end
      )

      adapter = args[:adapter].tap { |a| verify_adapter!(a) }
      @responder = objectify(
        exceptions: exceptions,
        adapter: adapter
      )
    end

    private

    def objectify(hash)
      OpenStruct.new(hash)
    end

    def exception_defaults
      EXCEPTIONS.reduce({}) { |acc, ex| acc.merge(ex => nil) }
    end

    def verify_adapter!(adapter)
      current_adapter_methods = Set[*(adapter.methods - Object.methods)]
      required_adapter_methods = ADAPTER_METHODS.to_set

      return if current_adapter_methods == required_adapter_methods

      missing = current_adapter_methods.subtract(required_adapter_methods)

      raise ArgumentError, "responder.adapter must implement: #{missing}"
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
