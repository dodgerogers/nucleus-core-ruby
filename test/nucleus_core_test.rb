require "test_helper"

describe NucleusCore do
  subject { NucleusCore.configuration }

  describe "#configure" do
    describe "exceptions" do
      it "initializes with expected exception mapping" do
        exceptions = subject.exceptions

        # mapping set in `test/test_helper.rb`
        refute_nil(exceptions)
        assert_equal([NotImplementedError], exceptions.bad_request)
        assert_equal([LoadError], exceptions.not_found)
        assert_equal([RuntimeError], exceptions.unprocessable)
        assert_equal([SecurityError], exceptions.unauthorized)
      end
    end
  end

  describe "#reset" do
    before { NucleusCoreTestConfiguration.init! }
    after { NucleusCoreTestConfiguration.init! }

    it "sets the config back to the initial state" do
      exceptions = subject.exceptions

      refute_empty(exceptions.bad_request)
      refute_empty(exceptions.not_found)
      refute_empty(exceptions.unprocessable)
      refute_empty(exceptions.unauthorized)

      NucleusCore.reset

      exceptions = NucleusCore.configuration.exceptions
      assert_empty(exceptions.bad_request)
      assert_empty(exceptions.not_found)
      assert_empty(exceptions.unprocessable)
      assert_empty(exceptions.unauthorized)
    end
  end
end
