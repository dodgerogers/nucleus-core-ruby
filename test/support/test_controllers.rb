require "securerandom"

class TestController
  def index
    Nucleus::Responder.handle_response do
      policy.enforce!(:can_write?)

      context, _process = SimpleWorkflow.call(total: 5)

      return Nucleus::View.new(total: context.total) if context.success?

      return context
    end
  end

  private

  def policy
    TestPolicy.new(current_user)
  end

  def current_user
    OpenStruct.new(id: SecureRandom.uuid)
  end
end
