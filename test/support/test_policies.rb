class TestPolicy < NucleusCore::Policy
  def read?
    true
  end

  def write?
    true
  end

  def owner?
    false
  end
end
