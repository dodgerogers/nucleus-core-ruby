module NucleusCore
  class ResponseAdapter
    def initialize(*args); end

    def call(_entity)
      raise NotImplementedError
    end

    def self.call(_entity)
      raise NotImplementedError
    end
  end
end
