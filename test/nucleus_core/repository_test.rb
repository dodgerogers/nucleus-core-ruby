require "test_helper"

describe NucleusCore::Repository do
  before do
    @repo = TestRepository
  end

  describe "#find!" do
    describe "when successful" do
      it "returns expected result object" do
        id = 2
        entity = @repo.find(id)

        assert_equal(id, entity.id)
      end
    end

    describe "when an exception is raised" do
      it "returns expected result object" do
        exception = assert_raises(NucleusCore::NotFound) do
          @repo.find(3)
        end

        assert_equal("cannot find thing with ID 3", exception.message)
      end
    end
  end
end
