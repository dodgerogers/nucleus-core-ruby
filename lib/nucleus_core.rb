require "ostruct"
require "json"
require "set"

response_adapters = File.join(__dir__, "nucleus_core", "response_adapters", "*.rb")
extensions = File.join(__dir__, "nucleus_core", "extensions", "*.rb")
view = File.join(__dir__, "nucleus_core", "views", "*.rb")
exceptions = File.join(__dir__, "nucleus_core", "exceptions", "*.rb")

[extensions, exceptions, response_adapters, view].each do |dir|
  Dir[dir].sort.each { |f| require f }
end

module NucleusCore
  autoload :CLI, "nucleus_core/cli"
  autoload :VERSION, "nucleus_core/version"
  autoload :BasicObject, "nucleus_core/basic_object"
  autoload :Aggregate, "nucleus_core/aggregate"
  autoload :Policy, "nucleus_core/policy"
  autoload :Operation, "nucleus_core/operation"
  autoload :Workflow, "nucleus_core/workflow"
  autoload :Responder, "nucleus_core/responder"

  class Configuration
    attr_accessor :response_adapter, :default_response_format, :logger
    attr_reader :exceptions

    RESPONSE_ADAPTER_METHODS = %i[
      render_json render_xml render_text render_pdf render_csv render_nothing set_header
    ].freeze

    def initialize
      @logger = nil
      @exceptions = format_exceptions
      @default_response_format = :json
    end

    def exceptions=(args={})
      @exceptions = format_exceptions(args)
    end

    private

    def objectify(hash)
      OpenStruct.new(hash)
    end

    ERROR_STATUSES = %i[not_found bad_request unauthorized unprocessable server_error].freeze

    def format_exceptions(exceptions={})
      exception_defaults = ERROR_STATUSES.reduce({}) { |acc, ex| acc.merge(ex => nil) }
      exceptions = (exceptions || exception_defaults)
        .slice(*exception_defaults.keys)
        .reduce({}) do |acc, (key, value)|
          acc.merge(key => Utils.wrap(value))
        end

      objectify(exceptions)
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
