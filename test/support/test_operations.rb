class TallyOperation < NucleusCore::Operation
  def required_args
    [:total]
  end

  def call
    validate_required_args!

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

class DummyOperation < NucleusCore::Operation
  def required_args
    %i[arg1 arg2]
  end

  def call
    validate_required_args!

    context.entity = OpenStruct.new(name: "Dummy")
  end

  def rollback
    context.rollback_called = true
  end
end
