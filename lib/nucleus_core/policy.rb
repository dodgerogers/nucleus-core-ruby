module NucleusCore
  class Policy
    attr_reader :client, :entity

    def initialize(client, entity=nil)
      @client = client
      @entity = entity
    end

    def enforce!(*policy_methods)
      policy_methods.each do |policy_method_and_args|
        next if send(*policy_method_and_args)

        name = Utils.wrap(policy_method_and_args).first
        message = "You do not have access to `#{name}`"

        raise NucleusCore::NotAuthorized, message
      end
    end
  end
end
