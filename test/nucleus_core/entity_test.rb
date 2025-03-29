require "test_helper"

describe NucleusCore::Entity do
  describe "#initialize" do
    before do
      @args = { name: "Bob", "number" => 123 }
    end

    subject { NucleusCore::Entity.new(@args) }

    it "sets expected methods" do
      assert_property(subject, :name, "Bob")
      assert_property(subject, :number, 123)
      assert_equal({ name: "Bob", number: 123 }, subject.to_h)
    end

    it "setter methods update __properties__" do
      assert_property(subject, :name, @args[:name])
      assert_property(subject, :number, @args["number"])

      subject.name = "new name"
      subject[:number] = 456
      subject["new"] = "value"

      assert_property(subject, :name, "new name")
      assert_property(subject, :number, 456)
      assert_property(subject, :new, "value")
    end
  end

  describe "hash interface" do
    subject { NucleusCore::Entity.new(foo: "bar", baz: 42, qux: nil) }

    it "#to_h" do
      assert_equal({ foo: "bar", baz: 42, qux: nil }, subject.to_h)
      assert_equal(subject.instance_variable_get(:@__properties__), subject.to_h)
    end

    it "#dup" do
      duped = subject.dup
      assert_equal(subject.to_h, duped.to_h)
      refute_equal(subject, duped)
      refute_same(
        subject.instance_variable_get(:@__properties__),
        duped.instance_variable_get(:@__properties__)
      )
    end

    it "#clone" do
      cloned = subject.clone
      assert_equal(subject.to_h, cloned.to_h)
      refute_equal(subject, cloned)
      refute_same(
        subject.instance_variable_get(:@__properties__),
        cloned.instance_variable_get(:@__properties__)
      )
    end

    it "#key?" do
      assert(subject.key?(:foo))
      assert(subject.key?("foo"))
      refute(subject.key?(:foozzz))
    end

    it "#respond_to?" do
      assert_respond_to(subject, :foo)
      assert_respond_to(subject, "foo")
      refute_respond_to(subject, :bazzz)
    end

    it "#dig" do
      nested_entity = NucleusCore::Entity.new(user: { "profile" => { "name" => "Alice" } })
      assert_equal("Alice", nested_entity.dig(:user, :profile, :name))
      refute_equal("Alice", nested_entity.dig(:user, "profile", :name))
      assert_nil(nested_entity.dig(:user, :profile, :unknown))
    end

    it "#delete" do
      assert_equal("bar", subject.delete(:foo))
      assert_equal(42, subject.delete(:baz))
      refute(subject.key?(:foo))
      refute(subject.key?(:baz))
    end

    it "#merge!" do
      subject.merge!(
        new_key: "new_value",
        foo: 123,
        "string" => "val",
        [1, 2, 3] => "array",
        { key: "val" } => "hash"
      )
      assert_equal("new_value", subject[:new_key])
      assert_equal(123, subject[:foo])
      assert_equal("val", subject[:string])
      assert_equal("array", subject[[1, 2, 3]])
      assert_equal("hash", subject[{ key: "val" }])
      assert(subject.key?(:"[1, 2, 3]"))
      assert(subject.key?(:"{:key=>\"val\"}"))
    end

    it "#each" do
      collected = []
      subject.each { |k, v| collected << [k, v] }
      assert_equal([[:foo, "bar"], [:baz, 42], [:qux, nil]], collected)
    end

    it "#map" do
      collected = subject.map { |k, v| [k, v] }
      assert_equal([[:foo, "bar"], [:baz, 42], [:qux, nil]], collected)
    end

    it "#keys" do
      assert_equal(%i[foo baz qux], subject.keys)
    end

    it "#inspect" do
      assert_equal("#<NucleusCore::Entity:#{subject.object_id} {:foo=>\"bar\", :baz=>42, :qux=>nil}>", subject.inspect)
    end

    describe "#symbolize_keys" do
      before do
        @original = { "foo" => "bar", "baz" => 42, "qux" => nil }
      end

      subject { NucleusCore::Entity.new(@original) }

      it "copies hash, whilst converting all keys to symbols" do
        result = subject.to_h
        refute_equal(@original, result)
        assert_equal({ foo: "bar", baz: 42, qux: nil }, result)
      end
    end
  end

  def assert_property(obj, key, expected_value)
    assert_equal(expected_value, obj.send(key.to_sym))
    assert_equal(expected_value, obj[key.to_sym])
    assert_equal(expected_value, obj[key.to_s])
  end
end
