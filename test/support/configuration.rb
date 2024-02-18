require "logger"

class NucleusCoreTestConfiguration
  def self.init!
    NucleusCore.configure do |config|
      # Uncomment for debugging
      # config.logger = ::Logger.new($stdout)
      config.default_response_format = :json
      config.request_exceptions = {
        bad_request: NotImplementedError,
        unauthorized: SecurityError,
        forbidden: NameError,
        not_found: LoadError,
        unprocessable: RuntimeError
      }
    end
  end
end
