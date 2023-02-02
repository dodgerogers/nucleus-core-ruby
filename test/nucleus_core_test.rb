require "test_helper"

describe NucleusCore do
  subject { NucleusCore.configuration }

  describe "#configure" do
    describe "exceptions_map" do
      it "initializes with expected exception mapping" do
        exceptions = subject.exceptions_map

        # mapping set in `test/test_helper.rb`
        refute_nil(exceptions)
        assert_equal([NotImplementedError], exceptions.bad_request)
        assert_equal([LoadError], exceptions.not_found)
        assert_equal([RuntimeError], exceptions.unprocessable)
        assert_equal([SecurityError], exceptions.unauthorized)
        assert_equal([SignalException], exceptions.server_error)
      end
    end
  end

  # TODO: uncomment
  # describe "#reset" do
  #   after { NucleusCoreTestConfiguration.init! }

  #   it "sets the config back to the initial state" do
  #     exceptions = subject.exceptions_map

  #     refute_nil(exceptions.bad_request)
  #     refute_nil(exceptions.not_found)
  #     refute_nil(exceptions.unprocessable)
  #     refute_nil(exceptions.unauthorized)
  #     refute_nil(exceptions.server_error)

  #     NucleusCore.reset

  #     exceptions = NucleusCore.configuration.exceptions_map

  #     assert_nil(exceptions.bad_request)
  #     assert_nil(exceptions.not_found)
  #     assert_nil(exceptions.unprocessable)
  #     assert_nil(exceptions.unauthorized)
  #     assert_nil(exceptions.server_error)
  #   end
  # end
end
