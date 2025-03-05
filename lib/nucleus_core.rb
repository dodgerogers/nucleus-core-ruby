require "ostruct"
require "json"
require "set"

module NucleusCore
  # Core Components
  autoload :CLI, "nucleus_core/cli"
  autoload :Operation, "nucleus_core/operation"
  autoload :Responder, "nucleus_core/responder"
  autoload :RequestAdapter, "nucleus_core/request_adapter"
  autoload :ResponseAdapter, "nucleus_core/response_adapter"
  autoload :Entity, "nucleus_core/entity"
  autoload :View, "nucleus_core/view"
  autoload :Connector, "nucleus_core/connector"

  # Version
  autoload :VERSION, "nucleus_core/version"

  extensions = File.join(__dir__, "nucleus_core", "extensions", "*.rb")
  exceptions = File.join(__dir__, "nucleus_core", "exceptions.rb")
  workflow = File.join(__dir__, "nucleus_core", "workflow", "*.rb")
  [extensions, exceptions, workflow].each do |dir|
    Dir[dir].sort.each { |f| require f }
  end

  class Configuration
    attr_accessor :default_response_format, :logger
    attr_reader :request_exceptions

    def initialize
      @logger = nil
      @request_exceptions = format_request_exceptions
    end

    def request_exceptions=(args={})
      @request_exceptions = format_request_exceptions(args)
    end

    private

    def format_request_exceptions(args={})
      errors = %i[not_found bad_request unauthorized forbidden unprocessable]
      exceptions = errors.to_h { |name| [name, []] }.merge(args)
      exceptions.transform_values! { |values| Array(values) } # Ensure array

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
