class TestSimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json
    NucleusCore::View::Response.new(:json, content: to_h)
  end

  def xml
    NucleusCore::View::Response.new(:xml, content: "<xml></xml>")
  end

  def pdf
    NucleusCore::View::Response.new(:pdf)
  end

  def csv
    NucleusCore::View::Response.new(:csv, content: "#{to_h.keys.join(',')}\n#{to_h.values.join(',')}")
  end

  def text
    NucleusCore::View::Response.new(:text, content: to_h.values.join(", "))
  end
end
