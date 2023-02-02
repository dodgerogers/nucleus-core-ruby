class NucleusCoreTestConfiguration
  def self.init!
    NucleusCore.configure do |config|
      config.logger = nil
      config.exceptions_map = {
        bad_request: NotImplementedError,
        not_found: LoadError,
        unprocessable: RuntimeError,
        unauthorized: SecurityError,
        server_error: SignalException
      }
    end
  end
end
