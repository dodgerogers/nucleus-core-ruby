class TestResponseAdapter < NucleusCore::View::Response
  def self.json(entity)
    entity
  end

  def self.xml(entity)
    entity
  end

  def self.pdf(entity)
    entity
  end

  def self.csv(entity)
    entity
  end

  def self.text(entity)
    entity
  end

  def self.nothing(entity)
    entity
  end

  def self.set_header(*_args)
    nil
  end
end
