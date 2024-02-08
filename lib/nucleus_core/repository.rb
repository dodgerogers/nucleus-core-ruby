module NucleusCore
  class Repository
    class Result
      attr_accessor :entity, :exception
    end

    def self.execute(&block)
      Result.new.tap do |res|
        res.entity = Utils.capture(&block)
      rescue NucleusCore::BaseException, *NucleusCore.configuration.data_access_exceptions => e
        res.exception = e
      end
    end
  end
end
