require "test_helper"

describe Nucleus::BasicObject do
  describe "#initialize" do
    before do
      @args = { name: "Bob", number: 123 }
    end

    subject { Nucleus::BasicObject.new(@args) }

    it "sets expected methods, and instance variables" do
      to = subject

      assert_equal("Bob", to.name)
      assert_equal("Bob", to.instance_variable_get(:@name))
      assert_equal(123, to.number)
      assert_equal(123, to.instance_variable_get(:@number))
    end
  end
end
