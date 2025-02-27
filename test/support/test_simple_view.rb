class TestSimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json
    build_response(content: to_h)
  end

  def xml
    build_response(content: "<xml></xml>")
  end

  def pdf
    build_response(content: "pdf...")
  end

  def csv
    build_response(content: "#{to_h.keys.join(',')}\n#{to_h.values.join(',')}")
  end

  def text
    build_response(content: to_h.values.join(", "))
  end
end
