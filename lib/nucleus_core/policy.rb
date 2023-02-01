require "nucleus_core/exceptions"

module NucleusCore
  class Policy
    attr_reader :user, :record

    def initialize(user, record=nil)
      @user = user
      @record = record
    end

    def enforce!(*policy_methods)
      policy_methods.each do |policy_method_and_args|
        next if send(*policy_method_and_args)

        name = Array.wrap(policy_method_and_args).first
        message = "You do not have access to: #{name}"

        raise NucleusCore::NotAuthorized, message
      end
    end
  end
end
