require "test_helper"
require "ostruct"

class TestPolicy < Nucleus::Policy
  def can_read?
    true
  end

  def can_write?
    true
  end

  def owner?
    false
  end
end

class PolicyTest < Minitest::Test
  def setup
    @user = OpenStruct.new(id: 1)
    @record = OpenStruct.new(id: 1)
    @policy = TestPolicy.new(@user, @record)
  end

  def test_initialization_with_hash
    assert_predicate(@policy, :can_read?)
    assert_predicate(@policy, :can_write?)
  end

  def test_positive_enforce!
    assert(@policy.enforce!(:can_read?, :can_write?))
  end

  def test_negative_enforce!
    exception = assert_raises(Nucleus::NotAuthorized) { @policy.enforce!(:owner?) }
    assert_equal "You do not have access to: owner?", exception.message
  end
end
