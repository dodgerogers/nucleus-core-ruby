class TestRepository < NucleusCore::Repository
  def self.find(id)
    execute do |result|
      raise NucleusCore::NotFound.new(message: "cannot find thing with ID #{id}") if id.odd?

      result.entity = OpenStruct.new(id: id, ref: SecureRandom.hex)
    end
  end

  def self.persist_process(_process, _attrs={})
    nil
  end

  def self.failing_persist_process(_process, _attrs={})
    false
  end
end
