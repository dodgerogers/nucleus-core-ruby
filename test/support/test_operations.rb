require "nucleus"

class TestOperation < Nucleus::Operation
  def call
    context.fail!("total has reached max", exception: StandardError.new) if context.total >= 20

    context.total += 1
  end

  def rollback
    context.total -= 1
  end
end
