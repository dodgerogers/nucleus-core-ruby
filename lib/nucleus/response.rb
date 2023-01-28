require "nucleus/rack"

class Nucleus::Response < Nucleus::BasicObject
  attr_accessor :content, :filename, :disposition, :headers, :status, :location

  def initialize(attrs={})
    attrs
      .reverse_merge(defaults)
      .with_indifferent_access
      .tap({}) do |hash|
        hash[:status] = status_code(hash[:status])
      end

    super(attrs)
  end

  private

  def defaults
    { context: "", headers: {}, status: 200, location: nil }
  end

  def status_code(status=nil)
    status = Nucleus::Rack::Utils.status_code(status)
    default_status = 200

    status.zero? ? default_status : status
  end
end

class Nucleus::Json::Response < Nucleus::Response
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/json")

    super(attrs)
  end
end

class Nucleus::Xml::Response < Nucleus::Response
  def initialize(attrs={})
    attrs = attrs.merge(type: "application/xml")

    super(attrs)
  end
end

class Nucleus::Csv::Response < Nucleus::Response
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "attachment",
      filename: attributes.fetch(:filename) { "response.csv" },
      type: "text/csv; charset=UTF-8;"
    )

    super(attrs)
  end
end

class Nucleus::Pdf::Response < Nucleus::Response
  def initialize(attrs={})
    attrs = attrs.merge(
      disposition: "inline",
      filename: attributes.fetch(:filename) { "response.pdf" },
      type: "application/pdf"
    )

    super(attrs)
  end
end
