module NucleusCore
  class Repository
    class Result
      attr_accessor :entity, :exception
    end

    def self.execute(&block)
      result = Result.new

      Utils.capture(result, &block)

      result
    end
  end
end
