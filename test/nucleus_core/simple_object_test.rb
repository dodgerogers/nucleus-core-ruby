require "test_helper"

describe NucleusCore::SimpleObject do
  describe "#initialize" do
    before do
      @args = { name: "Bob", "number" => 123 }
    end

    subject { NucleusCore::SimpleObject.new(@args) }

    it "sets expected methods, and instance variables" do
      obj = subject

      assert_property(obj, "Bob", :name)
      assert_property(obj, 123, :number)
      assert_equal(@args, obj.to_h)
    end

    it "setter methods update __attributes__" do
      obj = subject

      assert_property(obj, @args[:name], :name)
      assert_property(obj, @args["number"], :number)

      new_name = "new name"
      new_number = 456
      obj.name = new_name
      obj[:number] = new_number
      obj["new"] = "value"

      assert_property(obj, new_name, :name)
      assert_property(obj, new_number, :number)
      assert_property(obj, "value", :new)
    end

    it "implements `to_h`" do
      assert_equal(subject.instance_variable_get(:@__attributes__), subject.to_h)
    end
  end

  def assert_property(obj, expected_value, key)
    assert_equal(expected_value, obj.send(key.to_sym))
    assert_equal(expected_value, obj[key.to_sym])
    assert_equal(expected_value, obj[key.to_s])
  end
end
