require "ostruct"
require "json"
require "set"

extensions = File.join(__dir__, "nucleus_core", "extensions", "*.rb")
exceptions = File.join(__dir__, "nucleus_core", "exceptions", "*.rb")
views = File.join(__dir__, "nucleus_core", "views", "*.rb")
response_adapters = File.join(__dir__, "nucleus_core", "response_adapters", "*.rb")
request_adapters = File.join(__dir__, "nucleus_core", "request_adapters", "*.rb")

[extensions, exceptions, views, response_adapters, request_adapters].each do |dir|
  Dir[dir].sort.each { |f| require f }
end

module NucleusCore
  autoload :CLI, "nucleus_core/cli"
  autoload :VERSION, "nucleus_core/version"
  autoload :Operation, "nucleus_core/operation"
  autoload :Workflow, "nucleus_core/workflow"
  autoload :Responder, "nucleus_core/responder"
  autoload :SimpleObject, "nucleus_core/basic_object"

  class Configuration
    attr_accessor :default_response_format, :logger
    attr_reader :exceptions

    def initialize
      @logger = nil
      @exceptions = format_exceptions
      @default_response_format = :json
    end

    def exceptions=(args={})
      @exceptions = format_exceptions(args)
    end

    private

    ERROR_STATUSES = %i[not_found bad_request unauthorized unprocessable].freeze

    def format_exceptions(exceptions={})
      exception_defaults = ERROR_STATUSES.reduce({}) { |acc, ex| acc.merge(ex => nil) }
      exceptions = (exceptions || exception_defaults)
        .slice(*exception_defaults.keys)
        .reduce({}) do |acc, (key, value)|
          acc.merge(key => Utils.wrap(value))
        end

      OpenStruct.new(exceptions)
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
