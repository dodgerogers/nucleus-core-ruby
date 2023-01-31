require "test_helper"

describe Nucleus do
  subject { Nucleus.configuration }

  describe "#configure" do
    describe "exceptions_map" do
      it "initializes with expected exception mapping" do
        exceptions = subject.exceptions_map

        refute_nil(exceptions)
        # mapping set in `test/test_helper.rb`
        assert_equal([NotImplementedError], exceptions.bad_request)
        assert_equal([LoadError], exceptions.not_found)
        assert_equal([RuntimeError], exceptions.unprocessable)
        assert_equal([SecurityError], exceptions.unauthorized)
        assert_equal([SignalException], exceptions.server_error)
      end

      it "initializes with expected response_adapter" do
        adapter = subject.response_adapter

        refute_nil(adapter)

        Nucleus::Configuration::ADAPTER_METHODS.each do |adapter_method|
          assert_respond_to(adapter, adapter_method)
        end
      end
    end
  end

  # describe "#reset" do
  #   after { init_configuration! }

  #   it "sets the config back to the initial state" do
  #     exceptions = subject.exceptions_map

  #     refute_nil(exceptions.bad_request)
  #     refute_nil(exceptions.not_found)
  #     refute_nil(exceptions.unprocessable)
  #     refute_nil(exceptions.unauthorized)
  #     refute_nil(exceptions.server_error)

  #     Nucleus.reset

  #     exceptions = Nucleus.configuration.exceptions_map

  #     assert_nil(exceptions.bad_request)
  #     assert_nil(exceptions.not_found)
  #     assert_nil(exceptions.unprocessable)
  #     assert_nil(exceptions.unauthorized)
  #     assert_nil(exceptions.server_error)
  #   end
  # end
end
