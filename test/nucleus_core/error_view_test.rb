require "test_helper"

describe NucleusCore::ErrorView do
  describe "#initialize" do
    subject { NucleusCore::ErrorView.new(message: "message", status: :not_found, errors: [1, 2, 3]) }

    it "has expected parent class" do
      assert_equal(NucleusCore::View, NucleusCore::ErrorView.superclass)
    end

    it "has the expected properties" do
      view = subject

      assert_equal("message", view.message)
      assert_equal(:not_found, view.status)
      assert_equal([1, 2, 3], view.errors)
      assert_equal(3, view.to_h.keys.length)
    end

    it "implements `json_response`" do
      response = subject.json_response

      assert_equal(:json, response.format)
      assert_equal(404, response.status)
    end

    describe "defaults" do
      subject { NucleusCore::ErrorView.new }

      it "has the expected properties" do
        view = subject

        assert_nil(view.message)
        assert_equal(:internal_server_error, view.status)
        assert_empty(view.errors)
        assert_equal(3, view.to_h.keys.length)
      end
    end
  end
end
