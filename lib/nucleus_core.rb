require "ostruct"
require "json"
require "set"

module NucleusCore
  autoload :CLI, "nucleus_core/cli"
  autoload :VERSION, "nucleus_core/version"
  autoload :Operation, "nucleus_core/operation"
  autoload :Responder, "nucleus_core/responder"
  autoload :RequestAdapter, "nucleus_core/request_adapter"
  autoload :Worker, "nucleus_core/worker"
  autoload :SimpleObject, "nucleus_core/simple_object"
  autoload :Policy, "nucleus_core/policy"
  autoload :Repository, "nucleus_core/repository"
  autoload :View, "nucleus_core/view"
  autoload :Connector, "nucleus_core/connector"

  extensions = File.join(__dir__, "nucleus_core", "extensions", "*.rb")
  exceptions = File.join(__dir__, "nucleus_core", "exceptions.rb")
  workflow = File.join(__dir__, "nucleus_core", "workflow", "*.rb")
  [extensions, exceptions, workflow].each do |dir|
    Dir[dir].sort.each { |f| require f }
  end

  class Configuration
    attr_accessor :default_response_format, :logger, :response_formats
    attr_reader :request_exceptions

    def initialize
      @logger = nil
      @request_exceptions = format_request_exceptions
      @response_formats = {}
    end

    def request_exceptions=(args={})
      @request_exceptions = format_request_exceptions(args)
    end

    private

    def format_request_exceptions(args={})
      errors = %i[not_found bad_request unauthorized forbidden unprocessable]
      exceptions = errors
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
