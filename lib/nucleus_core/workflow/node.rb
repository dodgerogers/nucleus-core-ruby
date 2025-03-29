module NucleusCore
  module Workflow
    # The Node class represents a single step within a workflow graph.
    # It encapsulates the data and behavior associated with that step.
    #
    # Key Attributes:
    # - state:       The unique identifier for this node within the workflow.
    # - operation:   The operation to be executed when the workflow reaches this node.
    # - rollback:    An optional operation to be performed when rolling back from this node.
    # - transitions: A hash defining the possible transitions from this node to other nodes.
    # - prepare_context: An optional procedure to prepare the context before the operation.
    # - determine_signal: An optional procedure to determine the next signal.
    #
    # Design Rationale:
    #
    # 1.  Attribute Management:
    #     -   The Node class uses a combination of dynamic method definition and
    #         instance variable manipulation to manage its attributes. This approach
    #         is chosen to provide a flexible and concise way to define and access
    #         node properties.
    #     -   The `ATTRIBUTES` constant defines the set of valid attributes for a Node.
    #         This provides a centralized and easily modifiable list of node properties.
    #
    # 2.  Initialization:
    #     -   The `initialize` method dynamically sets instance variables based on the
    #         provided `attrs` hash. This allows for a more flexible and less verbose
    #         node creation. Instead of defining individual arguments for each attribute,
    #         a single hash can be used to pass all the necessary data.
    #     -   Example:
    #         `Node.new(state: :my_state, operation: my_operation, transitions: { next: :next_state })`
    #
    # 3.  Dynamic Method Definition:
    #     -   The `define_method` method is used to dynamically create getter/setter-like
    #         methods for each attribute. This approach offers several advantages:
    #         -   **Conciseness:** It reduces boilerplate code by avoiding the need to
    #             manually define getter and setter methods for each attribute.
    #         -   **Flexibility:** It allows for easy modification of the set of attributes
    #             by simply updating the `ATTRIBUTES` constant.
    #         -   **Lazy Initialization:** The getter-like methods implement a form of
    #             lazy initialization. They only set the instance variable if it hasn't
    #             been set yet, allowing for default values or delayed assignment.
    #
    # 4.  Lazy Initialization and Default Values:
    #     -   The dynamically defined methods provide a mechanism for lazy initialization
    #         of instance variables. This means that an attribute's value is only set
    #         when it's first accessed.
    #     -   If a value is not provided during initialization or explicitly set, the
    #         getter-like method will return `nil`.
    #     -   This pattern is useful for attributes that may not always be required or
    #         whose values may be determined later in the workflow execution.
    #
    # 5.  Thread Safety:
    #     -   It's important to note that the lazy initialization pattern implemented in
    #         this class is *not* thread-safe. If multiple threads access and modify
    #         the same Node object concurrently, there is a risk of race conditions
    #         and inconsistent state. If thread safety is a requirement, appropriate
    #         synchronization mechanisms (e.g., mutexes) should be employed.
    #

    class Node
      ATTRIBUTES = %i[state operation rollback transitions prepare_context determine_signal].freeze

      # Initializes a new Node object.
      #
      # @param attrs [Hash] A hash of attributes to set for the node.
      #                     Keys correspond to the attributes in the ATTRIBUTES constant,
      #                     and values are the initial values for those attributes.
      #                     Any attributes not provided in this hash will be initialized to nil.
      def initialize(attrs={})
        ATTRIBUTES.each { |attr| instance_variable_set(:"@#{attr}", attrs[attr]) }
      end

      # Dynamically defines getter/setter-like methods for each attribute.
      #
      # These methods provide lazy initialization:
      # - If a value is provided, it sets the instance variable.
      # - If no value is provided, it returns the current value of the instance variable
      #   (which will be nil if it has not been set).
      ATTRIBUTES.each do |attribute|
        define_method(attribute) do |value=nil|
          instance_variable_set(:"@#{attribute}", value) if instance_variable_get(:"@#{attribute}").nil?

          instance_variable_get(:"@#{attribute}")
        end
      end
    end
  end
end
