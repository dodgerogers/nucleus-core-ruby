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
