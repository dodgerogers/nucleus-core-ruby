require "test_helper"

class NucleusTest < Minitest::Test
  def setup
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

  def test_configuration
    exceptions = Nucleus.configuration&.responder&.exceptions

    refute_nil(exceptions)
    assert_equal(Nucleus::BadRequest, exceptions.bad_request)
    assert_equal(Nucleus::NotFound, exceptions.not_found)
    assert_equal(Nucleus::Unprocessable, exceptions.unprocessable)
    assert_equal(Nucleus::NotAuthorized, exceptions.unauthorized)
    assert_equal(Nucleus::BaseException, exceptions.server_error)
  end

  def test_resets_configuration
    refute_nil(Nucleus.configuration.responder)

    Nucleus.reset

    assert_nil(Nucleus.configuration.responder)
  end
end
