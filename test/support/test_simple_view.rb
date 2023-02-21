class TestSimpleView < NucleusCore::View
  def initialize(attrs={})
    super(attrs)
  end

  def json_response
    NucleusCore::JsonResponse.new
  end

  def xml_response
    NucleusCore::XmlResponse.new
  end

  def pdf_response
    NucleusCore::PdfResponse.new
  end

  def csv_response
    NucleusCore::CsvResponse.new
  end

  def text_response
    NucleusCore::TextResponse.new
  end
end
