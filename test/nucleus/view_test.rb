require "test_helper"

class ViewTest < Minitest::Test
  def test_subclass
    assert_equal(Nucleus::View.superclass, Nucleus::BasicObject)
  end
end
