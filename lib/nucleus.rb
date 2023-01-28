require "ostruct"
require "nucleus/exceptions"
require "json"

module Nucleus
  autoload :CLI, "nucleus/cli"
  autoload :VERSION, "nucleus/version"
  autoload :BasicObject, "nucleus/basic_object"
  autoload :View, "nucleus/view"
  autoload :Response, "nucleus/responses"
  autoload :Aggregate, "nucleus/aggregate"
  autoload :Policy, "nucleus/policy"
  autoload :Operation, "nucleus/operation"
  autoload :Workflow, "nucleus/workflow"
  autoload :Responder, "nucleus/responder"

  class Configuration
    attr_reader :logger, :responder

    def logger=(logger)
      @logger = logger
    end

    def responder=(args={})
      statuses = %i(not_found bad_request forbidden unprocessable server_error)
      exception_map = args
        .fetch(:exceptions) { {} }
        .slice(*statuses)
        .reduce({}) do |acc, (key, value)|
          acc.merge(key => Array.wrap(value))
        end

      @responder = objectify(exceptions: objectify(exception_map))
    end

    private

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
