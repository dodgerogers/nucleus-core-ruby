require "nucleus/responses"

class Nucleus::View < Nucleus::BasicObject
  def json_response
    Nucleus::Json::Response.new(content: self.to_h, status: :ok)
  end
end

class Nucleus::Errors::View < Nucleus::View
  def initialize(attrs={})
    attrs = {}.tap do |a|
      a[:status] = attributes.fetch(:status) { :unprocessable_entity }
      a[:message] = attributes.fetch(:message) { nil }
      a[:errors] = attributes.fetch(:errors) { [] }
      a[:headers] = attributes.fetch(:headers) { {} }
    end

    super(attrs)
  end

  def to_h
    super.except(:headers)
  end

  def json_response
    Nucleus::Json::Response.new(content: self.to_h, status: self.status, headers: self.headers)
  end
end
