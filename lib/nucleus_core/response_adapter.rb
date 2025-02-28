module NucleusCore
  class ResponseAdapter
    def call(_entity)
      raise NotImplementedError
    end

    def self.call(_entity)
      raise NotImplementedError
    end
  end
end
