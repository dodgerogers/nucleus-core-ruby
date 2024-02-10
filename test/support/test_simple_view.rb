class TestSimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json_response
    NucleusCore::View::Response.new(:json, content: to_h)
  end

  def xml_response
    NucleusCore::View::Response.new(:xml, content: "<xml></xml>")
  end

  def pdf_response
    NucleusCore::View::Response.new(:pdf)
  end

  def csv_response
    NucleusCore::View::Response.new(:csv, content: "#{to_h.keys.join(',')}\n#{to_h.values.join(',')}")
  end

  def text_response
    NucleusCore::View::Response.new(:text, content: to_h.values.join(", "))
  end
end
