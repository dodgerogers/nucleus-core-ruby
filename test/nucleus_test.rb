require "test_helper"

describe Nucleus do
  before do
    Nucleus.configure do |config|
      config.responder = {
        exceptions: {
          bad_request: NotImplementedError,
          not_found: LoadError,
          unprocessable: RuntimeError,
          unauthorized: SecurityError,
          server_error: SignalException
        },
        adapter: TestAdapter
      }
    end
  end

  describe "#configure" do
    describe "responder" do
      subject { Nucleus.configuration.responder }

      it "initializes with expected exception mapping" do
        exceptions = subject.exceptions

        refute_nil(exceptions)
        assert_equal([NotImplementedError], exceptions.bad_request)
        assert_equal([LoadError], exceptions.not_found)
        assert_equal([RuntimeError], exceptions.unprocessable)
        assert_equal([SecurityError], exceptions.unauthorized)
        assert_equal([SignalException], exceptions.server_error)
      end

      it "initializes with expected adapter methods" do
        adapter = subject.adapter

        refute_nil(adapter)
        Nucleus::Configuration::ADAPTER_METHODS.each do |adapter_method|
          assert_respond_to(adapter, adapter_method)
        end
      end
    end
  end

  describe "#reset" do
    it "sets the config back to the initial state" do
      exceptions = Nucleus.configuration.responder.exceptions

      refute_nil(exceptions.bad_request)
      refute_nil(exceptions.not_found)
      refute_nil(exceptions.unprocessable)
      refute_nil(exceptions.unauthorized)
      refute_nil(exceptions.server_error)

      Nucleus.reset

      exceptions = Nucleus.configuration.responder.exceptions

      assert_nil(exceptions.bad_request)
      assert_nil(exceptions.not_found)
      assert_nil(exceptions.unprocessable)
      assert_nil(exceptions.unauthorized)
      assert_nil(exceptions.server_error)
    end
  end
end
