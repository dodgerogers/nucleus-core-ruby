require "logger"

class NucleusCoreTestConfiguration
  def self.init!
    NucleusCore.configure do |config|
      # Uncomment for debugging
      # config.logger = ::Logger.new($stdout)
      config.default_response_format = :json
      config.exceptions = {
        bad_request: NotImplementedError,
        not_found: LoadError,
        unprocessable: RuntimeError,
        unauthorized: SecurityError
      }
    end
  end
end
