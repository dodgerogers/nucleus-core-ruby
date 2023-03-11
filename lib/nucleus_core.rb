require "ostruct"
require "json"
require "set"

module NucleusCore
  autoload :CLI, "nucleus_core/cli"
  autoload :VERSION, "nucleus_core/version"
  autoload :Operation, "nucleus_core/operation"
  autoload :Workflow, "nucleus_core/workflow"
  autoload :Responder, "nucleus_core/responder"
  autoload :RequestAdapter, "nucleus_core/request_adapter"
  autoload :ResponseAdapter, "nucleus_core/response_adapter"
  autoload :SimpleObject, "nucleus_core/simple_object"

  extensions = File.join(__dir__, "nucleus_core", "extensions", "*.rb")
  exceptions = File.join(__dir__, "nucleus_core", "exceptions", "*.rb")
  views = File.join(__dir__, "nucleus_core", "views", "*.rb")
  [extensions, exceptions, views].each do |dir|
    Dir[dir].sort.each { |f| require f }
  end

  class Configuration
    attr_accessor :default_response_format, :logger
    attr_reader :exceptions

    ERROR_STATUSES = %i[not_found bad_request unauthorized unprocessable].freeze

    def initialize
      @logger = nil
      @exceptions = format_exceptions
      @default_response_format = :json
    end

    def exceptions=(args={})
      @exceptions = format_exceptions(args)
    end

    private

    def format_exceptions(args={})
      exceptions = ERROR_STATUSES
        .reduce({}) { |acc, name| acc.merge(name => nil) }
        .merge(args)
        .transform_values { |values| Utils.wrap(values) }

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
