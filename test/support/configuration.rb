require "logger"

class NucleusCoreTestConfiguration
  def self.init!
    NucleusCore.configure do |config|
      config.logger = ::Logger.new($stdout)
      config.default_response_format = :json
      config.data_access_exceptions = [IOError]
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
