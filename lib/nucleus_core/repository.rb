# rubocop:disable Lint/EmptyClass:
module NucleusCore
  # The Repository class serves as an abstraction layer that defines the interactions
  # with a data source. It follows the repository pattern, encapsulating the set of
  # operations that can be performed on the data source. This class itself does not
  # contain any implementation details, but provides a contract for concrete repository
  # classes to implement.
  #
  # Purpose:
  # - To decouple the data access logic from the business logic.
  # - To provide a clear and consistent interface for data operations.
  # - To allow easy switching of data source implementations without affecting the rest
  #   of the application.
  #
  # Typical Usage:
  # - Define methods in this class that represent the various operations that can be
  #   performed on the data source (e.g., find, save, update, delete).
  # - Implement these methods in concrete subclasses that interact with specific data
  #   sources (e.g., databases, APIs, in-memory stores).
  #
  # Example:
  # - This abstract class might define methods like `find_by_id`, `save`, `update`, and
  #   `delete`.
  # - A concrete subclass like `UserRepository` would implement these methods to interact
  #   with the underlying data source (e.g., ActiveRecord for a database).
  #
  # Benefits:
  # - Promotes the Single Responsibility Principle by separating data access logic from
  #   business logic.
  # - Enhances testability by allowing mocking or stubbing of data source interactions.
  # - Improves maintainability and flexibility by providing a clear contract for data
  #   operations.
  #
  # Note:
  # - This class is intended to be subclassed, and its methods should be implemented in
  #   the concrete subclasses.
  #
  class Repository
    # Example method definitions (to be implemented by subclasses):
    #
    # def find_by_id(id)
    #   raise NotImplementedError, "This method must be implemented by subclasses"
    # end
    #
    # def save(entity)
    #   raise NotImplementedError, "This method must be implemented by subclasses"
    # end
    #
    # def update(entity)
    #   raise NotImplementedError, "This method must be implemented by subclasses"
    # end
    #
    # def delete(id)
    #   raise NotImplementedError, "This method must be implemented by subclasses"
    # end
  end
end
# rubocop:enable Lint/EmptyClass:
