require "test_helper"

describe Nucleus::BasicObject do
  describe "#initialize" do
    before do
      @args = { name: "Bob", number: 123 }
    end

    subject { TestObject.new(@args) }

    it "populates expected properties" do
      to = subject

      assert_equal("Bob", to.name)
      assert_equal(123, to.number)
    end

    describe "unknown property" do
      before do
        @args = { unknown: "property" }
      end

      it "sets a private instance variable, but not the public attribute method" do
        to = subject

        refute_respond_to(to, :unknown)
        assert_equal("property", to.instance_variable_get(:@unknown))
      end
    end
  end
end
