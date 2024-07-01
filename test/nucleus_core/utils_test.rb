require "test_helper"

describe Utils do
  describe ".status_code" do
    it "returns the correct status code for a symbol" do
      assert_equal(200, Utils.status_code(:ok))
      assert_equal(404, Utils.status_code(:not_found))
    end

    it "raises an ArgumentError for an unrecognized symbol" do
      assert_raises(ArgumentError) { Utils.status_code(:unknown_status) }
    end

    it "returns the integer value for an integer input" do
      assert_equal(200, Utils.status_code(200))
      assert_equal(404, Utils.status_code(404))
    end

    it "converts a string to an integer" do
      assert_equal(200, Utils.status_code("200"))
      assert_equal(404, Utils.status_code("404"))
    end
  end

  describe ".wrap" do
    it "wraps a non-array object in an array" do
      assert_equal(["string"], Utils.wrap("string"))
      assert_equal([123], Utils.wrap(123))
    end

    it "returns the array if the object is already an array" do
      assert_equal([1, 2, 3], Utils.wrap([1, 2, 3]))
    end

    it "returns an empty array if the object is nil" do
      assert_empty Utils.wrap(nil)
    end
  end

  describe ".capture" do
    it "captures the result of a block with arguments" do
      result = Utils.capture([1, 2]) { |a, b| a + b }
      assert_equal(3, result)
    end

    it "raises an error if the block raises an error" do
      assert_raises(RuntimeError) { Utils.capture { raise "error" } }
    end
  end

  describe ".subclass_of" do
    it "returns true if the entity is a subclass of any given class" do
      assert(Utils.subclass_of(String, Object))
      assert(Utils.subclass_of(String, Object, BasicObject))
    end

    it "returns false if the entity is not a subclass of any given class" do
      refute(Utils.subclass_of(String, Array))
    end
  end

  describe ".to_const" do
    it "returns the constant for a valid constant name" do
      assert_equal(String, Utils.to_const("String"))
    end

    it "returns nil for an invalid constant name" do
      assert_nil(Utils.to_const("NonExistentConstant"))
    end
  end
end
