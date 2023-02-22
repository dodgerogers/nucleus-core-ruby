class TestOperation < NucleusCore::Operation
  def call
    context.total ||= 0

    raise NucleusCore::Unprocessable, "total has reached max" if context.total >= 20

    context.total += 1
  rescue NucleusCore::Unprocessable => e
    context.fail!(e.message, exception: e)
  end

  def rollback
    context.total -= 1
  end
end
