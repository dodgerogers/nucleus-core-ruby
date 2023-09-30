class TestPolicy < NucleusCore::Policy
  def read?
    true
  end

  def even?(value_1, value_2)
    (value_1 + value_2).even?
  end
end
