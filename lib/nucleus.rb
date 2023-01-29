require "ostruct"
require "nucleus/exceptions"
require "json"

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

    def initialize
      @responder = objectify(exceptions: objectify(exception_defaults))
      @logger = nil
    end

    def responder=(args={})
      exception_map = args
        .fetch(:exceptions, exception_defaults)
        .slice(*exception_defaults.keys)
        .reduce({}) do |acc, (key, value)|
          acc.merge(key => Array.wrap(value))
        end

      @responder = objectify(exceptions: objectify(exception_map))
    end

    private

    def exception_defaults
      {
        not_found: nil,
        bad_request: nil,
        unauthorized: nil,
        unprocessable: nil,
        server_error: nil
      }
    end

    def objectify(hash)
      OpenStruct.new(hash)
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
