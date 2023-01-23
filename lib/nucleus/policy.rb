require "nucleus/exceptions"

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

        is_array = policy_method_and_args.respond_to?(:first)
        name = (is_array && policy_method_and_args.first) || policy_method_and_args
        message = "You do not have access to: #{name}"

        raise Nucleus::NotAuthorized, message
      end
    end
  end
end
