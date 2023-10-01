class TestOperation < NucleusCore::Operation
  def required_args
    [:total]
  end

  def call
    validate_required_args!

    context.total ||= 0

    raise NucleusCore::Unprocessable, "total has reached max" if context.total > 20

    isolate(changes: context.total)

    context.total += 1
  rescue NucleusCore::Unprocessable => e
    context.fail!(e.message, exception: e)
  end

  def rollback
    change = isolated.fetch(:changes, 0)
    context.total -= change
  end
end
