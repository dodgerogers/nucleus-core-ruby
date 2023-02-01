require "ostruct"
require "nucleus_core/exceptions"
require "json"
require "set"

Dir[File.join(__dir__, "nucleus_core", "extensions", "*.rb")].sort.each { |file| require file }

module NucleusCore
  autoload :CLI, "nucleus_core/cli"
  autoload :VERSION, "nucleus_core/version"
  autoload :BasicObject, "nucleus_core/basic_object"
  autoload :View, "nucleus_core/views/view"
  autoload :ErrorView, "nucleus_core/views/error_view"
  autoload :ResponseAdapter, "nucleus_core/response_adapter"
  autoload :Aggregate, "nucleus_core/aggregate"
  autoload :Policy, "nucleus_core/policy"
  autoload :Operation, "nucleus_core/operation"
  autoload :Workflow, "nucleus_core/workflow"
  autoload :Responder, "nucleus_core/responder"

  class Configuration
    attr_reader :exceptions_map, :response_adapter
    attr_accessor :logger

    def initialize
      @logger = nil
      @response_adapter = nil
      @exceptions_map = nil
    end

    def exceptions_map=(args={})
      @exceptions_map = format_exceptions(args)
    end

    def response_adapter=(adapter)
      @response_adapter = format_adapter(adapter)
    end

    private

    def objectify(hash)
      OpenStruct.new(hash)
    end

    ERROR_STATUSES = %i[not_found bad_request unauthorized unprocessable server_error].freeze

    def format_exceptions(exceptions={})
      exception_defaults = ERROR_STATUSES.reduce({}) { |acc, ex| acc.merge(ex => nil) }

      objectify(
        (exceptions || exception_defaults)
            .slice(*exception_defaults.keys)
            .reduce({}) do |acc, (key, value)|
              acc.merge(key => Array.wrap(value))
            end
      )
    end

    def format_adapter(adapter={})
      adapter.tap do |a|
        verify_adapter!(a)
      end
    end

    ADAPTER_METHODS = %i[
      render_json render_xml render_text render_pdf render_csv render_nothing set_header
    ].freeze

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
