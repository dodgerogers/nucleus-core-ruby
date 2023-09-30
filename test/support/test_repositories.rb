class TestRepository < NucleusCore::Repository
  def self.find(id)
    execute do
      raise NucleusCore::NotFound.new(message: "cannot find thing with ID #{id}") if id.odd?

      OpenStruct.new(id: id, ref: SecureRandom.hex)
    end
  end
end
