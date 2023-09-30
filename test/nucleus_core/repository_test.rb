require "test_helper"

describe NucleusCore::Repository do
  before do
    @repo = TestRepository
  end

  describe "#find!" do
    describe "when successful" do
      it "returns expected result object" do
        id = 2
        result = @repo.find(id)

        assert_equal(id, result.entity.id)
        assert_nil(result.exception)
      end
    end

    describe "when an exception is raise" do
      it "returns expected result object" do
        id = 3
        result = @repo.find(id)

        assert_nil(result.entity)
        assert_instance_of(NucleusCore::NotFound, result.exception)
      end
    end
  end
end
