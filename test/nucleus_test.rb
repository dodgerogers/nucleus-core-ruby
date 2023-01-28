require "test_helper"

describe Nucleus do
  before do
    Nucleus.configure do |config|
      config.responder = {
        exceptions: {
          bad_request: Nucleus::BadRequest,
          not_found: Nucleus::NotFound,
          unprocessable: Nucleus::Unprocessable,
          unauthorized: Nucleus::NotAuthorized,
          server_error: Nucleus::BaseException
        }
      }
    end
  end

  describe "#configure" do
    describe "responder" do
      it "initializes with expected values" do
        exceptions = Nucleus.configuration&.responder&.exceptions

        refute_nil(exceptions)
        assert_equal(Nucleus::BadRequest, exceptions.bad_request)
        assert_equal(Nucleus::NotFound, exceptions.not_found)
        assert_equal(Nucleus::Unprocessable, exceptions.unprocessable)
        assert_equal(Nucleus::NotAuthorized, exceptions.unauthorized)
        assert_equal(Nucleus::BaseException, exceptions.server_error)
      end
    end
  end

  describe "#reset" do
    it "sets the config back to the initial state" do
      refute_nil(Nucleus.configuration.responder)

      Nucleus.reset

      assert_nil(Nucleus.configuration.responder)
    end
  end
end
