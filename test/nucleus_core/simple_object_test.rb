require "test_helper"

describe NucleusCore::SimpleObject do
  describe "#initialize" do
    before do
      @args = { name: "Bob", "number" => 123 }
    end

    subject { NucleusCore::SimpleObject.new(@args) }

    it "sets expected methods, and instance variables" do
      obj = subject

      assert_property(obj, :name, "Bob")
      assert_property(obj, :number, 123)
      assert_equal(@args, obj.to_h)
    end

    it "setter methods update __attributes__" do
      obj = subject

      assert_property(obj, :name, @args[:name])
      assert_property(obj, :number, @args["number"])

      obj.name = "new name"
      obj[:number] = 456
      obj["new"] = "value"

      assert_property(obj, :name, "new name")
      assert_property(obj, :number, 456)
      assert_property(obj, :new, "value")
    end

    it "implements `to_h`" do
      assert_equal(subject.instance_variable_get(:@__attributes__), subject.to_h)
    end

    it "implements `key?`" do
      assert(subject.key?(:name))
      assert(subject.key?("name"))
      refute(subject.key?(:other_name))
    end
  end

  def assert_property(obj, key, expected_value)
    assert_equal(expected_value, obj.send(key.to_sym))
    assert_equal(expected_value, obj[key.to_sym])
    assert_equal(expected_value, obj[key.to_s])
  end
end
