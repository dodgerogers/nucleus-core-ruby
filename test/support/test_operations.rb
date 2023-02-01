class TestOperation < NucleusCore::Operation
  def call
    if context.total >= 20
      message = "total has reached max"
      context.fail!(message, exception: NucleusCore::Unprocessable.new(message))
    end

    context.total += 1
  end

  def rollback
    context.total -= 1
  end
end
