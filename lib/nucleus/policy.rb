module Nucleus
  class Policy
    attr_reader :user, :record

    def initialize(user, record=nil)
      @user   = user
      @record = record
    end

    def enforce!(*policy_methods)
      policy_methods.each do |policy_method_and_args|
        next if send(*policy_method_and_args)

        message = "You are not authorized to: #{policy_method_and_args.first}"

        raise ::Exceptions::NotAuthorized, message
      end
    end
  end
end
