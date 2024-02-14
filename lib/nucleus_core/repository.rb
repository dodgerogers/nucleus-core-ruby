module NucleusCore
  class Repository
    class Result
      attr_accessor :entity, :exception
    end

    def self.execute(&block)
      Result.new.tap do |result|
        Utils.capture(result, &block)
      rescue NucleusCore::BaseException, *NucleusCore.configuration.data_access_exceptions => e
        result.exception = e
      end
    end
  end
end
