class NucleusCore::ResponseAdapter < NucleusCore::BasicObject
  def initialize(attrs={})
    attributes = defaults
      .merge(attrs)
      .slice(*defaults.keys)
      .tap do |hash|
        hash[:status] = status_code(hash[:status])
      end

    super(attributes)
  end

  private

  def defaults
    { content: "", headers: {}, status: 200, location: nil }
  end

  def status_code(status=nil)
    status = Rack::Utils.status_code(status)
    default_status = 200

    status.zero? ? default_status : status
  end
end

class NucleusCore::NoResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(content: nil, type: "text/html; charset=utf-8")

    super(attrs)
  end
end

class NucleusCore::TextResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/text")

    super(attrs)
  end
end

class NucleusCore::JsonResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/json")

    super(attrs)
  end
end

class NucleusCore::XmlResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/xml")

    super(attrs)
  end
end

class NucleusCore::CsvResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "attachment",
      filename: attrs.fetch(:filename) { "response.csv" },
      type: "text/csv; charset=UTF-8;"
    )

    super(attrs)
  end
end

class NucleusCore::PdfResponse < NucleusCore::ResponseAdapter
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "inline",
      filename: attrs.fetch(:filename) { "response.pdf" },
      type: "application/pdf"
    )

    super(attrs)
  end
end
