require "test_helper"

class NucleusTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Nucleus::VERSION
  end
end
