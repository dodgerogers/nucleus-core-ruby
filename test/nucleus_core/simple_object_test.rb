require "test_helper"

describe NucleusCore::SimpleObject do
  describe "#initialize" do
    before do
      @args = { name: "Bob", number: 123 }
    end

    subject { NucleusCore::SimpleObject.new(@args) }

    it "sets expected methods, and instance variables" do
      obj = subject

      assert_equal("Bob", obj.name)
      assert_equal("Bob", obj.instance_variable_get(:@name))
      assert_equal(123, obj.number)
      assert_equal(123, obj.instance_variable_get(:@number))
      assert_equal(@args, obj.to_h)
    end

    it "setter methods update __attributes__" do
      obj = subject

      assert_equal(@args[:name], obj.to_h[:name])
      assert_equal(@args[:number], obj.to_h[:number])

      new_name = "new name"
      new_number = 456
      obj.name = new_name
      obj.number = new_number

      assert_equal(new_name, obj.__attributes__[:name])
      assert_equal(new_number, obj.__attributes__[:number])
    end

    it "implements `to_h`" do
      assert_equal(subject.__attributes__, subject.to_h)
    end
  end
end
