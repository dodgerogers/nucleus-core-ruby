module NucleusCore
  class Repository
    class Result
      attr_accessor :entity, :exception
    end

    def self.execute(&block)
      Result.new.tap do |res|
        res.entity = Utils.execute_block(&block)
      rescue NucleusCore::BaseException => e
        res.exception = e
      end
    end
  end
end
