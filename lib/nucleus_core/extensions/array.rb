module ArrayExtensions
  def self.wrap(object)
    return [] if object.nil?

    object.is_a?(Array) ? object : [object]
  end
end
