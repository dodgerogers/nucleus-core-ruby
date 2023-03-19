class TestSimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json_response
    NucleusCore::ResponseAdapter.new(:json, content: to_h)
  end

  def xml_response
    NucleusCore::ResponseAdapter.new(:xml, content: "<xml></xml>")
  end

  def pdf_response
    NucleusCore::ResponseAdapter.new(:pdf)
  end

  def csv_response
    NucleusCore::ResponseAdapter.new(:csv, content: "#{to_h.keys.join(',')}\n#{to_h.values.join(',')}")
  end

  def text_response
    NucleusCore::ResponseAdapter.new(:text, content: to_h.values.join(", "))
  end
end
