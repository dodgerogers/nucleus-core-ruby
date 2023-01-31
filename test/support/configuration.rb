class NucleusTestConfiguration
  def self.init!
    Nucleus.configure do |config|
      config.response_adapter = TestAdapter
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
