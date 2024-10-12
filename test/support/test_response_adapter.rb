class TestResponseAdapter < NucleusCore::View::Response
  def self.call(entity)
    entity
  end

  def self.set_header(*_args)
    nil
  end
end
