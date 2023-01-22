require "test_helper"

class AggregateTest < Minitest::Test
  def test_subclass
    assert_equal(Nucleus::Aggregate.superclass, Nucleus::BasicObject)
  end
end
