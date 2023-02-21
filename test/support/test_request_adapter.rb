class TestRequestAdapter
  def self.call(request={})
    request.slice(:format, :headers, :cookies, :parameters, :session, :context)
  end
end
