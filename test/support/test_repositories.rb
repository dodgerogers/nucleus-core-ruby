class TestRepository < NucleusCore::Repository
  def self.find(id)
    raise NucleusCore::NotFound, "cannot find thing with ID #{id}" if id.odd?

    OpenStruct.new(id: id, ref: SecureRandom.hex)
  end

  def self.persist_process(_process, _attrs={})
    nil
  end

  def self.failing_persist_process(_process, _attrs={})
    false
  end
end
