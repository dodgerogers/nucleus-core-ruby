require "test_helper"

describe NucleusCore::Worker do
  describe "call" do
    before do
      @args = {
        parameters: { key: "value" },
        other: "key"
      }
    end

    subject { TestWorker.call(@args) }

    it "executes successfully" do
      assert_equal("parameters, other", subject)
    end

    describe "when the adapter is an instance of NucleusCore::Worker::Adapter" do
      before do
        @args = {
          adapter: TestAdapter.new,
          parameters: { key: "value" },
          other: "key",
          new: "key"
        }
      end

      it "executes successfully" do
        assert_equal("parameters, other, new", subject)
      end
    end

    describe "when the adapter is a subclass of NucleusCore::Worker::Adapter" do
      before do
        @args = {
          adapter: TestAdapter,
          parameters: { key: "value" },
          other: "key",
          new: "key"
        }
      end

      it "executes successfully" do
        assert_equal("parameters, other, new", subject)
      end
    end

    describe "when class name and method are passed" do
      before do
        @args = {
          class_name: TestSimpleView.name,
          method_name: :new,
          id: "id"
        }
      end

      it "executes successfully" do
        res = subject

        assert_kind_of(NucleusCore::View, res)
        assert_equal(@args[:id], res.id)
      end

      describe "when non hash arguments are passed" do
        before do
          @args = {
            class_name: Array,
            method_name: :new,
            args: 3
          }
        end

        it "executes successfully" do
          res = subject

          assert_equal([nil, nil, nil], res)
        end
      end
    end

    describe "when the adapter does not subclass NucleusCore::Worker::Adapter" do
      before do
        @args = { adapter: "invalid" }
      end

      it "raises StandardError" do
        exception = assert_raises(StandardError) { subject }

        assert_equal("`invalid` does not subclass `NucleusCore::Worker::Adapter`", exception.message)
      end
    end
  end
end
