require "ostruct"
require "nucleus/exceptions"
require "json"

module Nucleus
  autoload :CLI, "nucleus/cli"
  autoload :VERSION, "nucleus/version"
  autoload :BasicObject, "nucleus/basic_object"
  autoload :View, "nucleus/view"
  autoload :Aggregate, "nucleus/aggregate"
  autoload :Policy, "nucleus/policy"
  autoload :Operation, "nucleus/operation"
  autoload :Workflow, "nucleus/workflow"
  autoload :Responder, "nucleus/responder"

  class Configuration
    attr_reader :responder

    def responder=(args={})
      exceptions = objectify(args[:exceptions])
      @responder = objectify(exceptions: exceptions)
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
