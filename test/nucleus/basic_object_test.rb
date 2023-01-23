require "test_helper"

class TestObject < Nucleus::BasicObject
  attr_accessor :name, :number
end

class BasicObjectTest < Minitest::Test
  def test_initialization_with_hash
    to = TestObject.new(name: "Bob", number: 123)

    assert_equal("Bob", to.name)
    assert_equal(123, to.number)
  end

  def test_initialization_with_unknown_property
    to = TestObject.new(unknown: "property")

    refute_respond_to(to, :unknown)
    assert_equal("property", to.instance_variable_get(:@unknown))
  end
end
