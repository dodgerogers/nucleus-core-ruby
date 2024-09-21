require "logger"

class NucleusCoreTestConfiguration
  def self.init!
    NucleusCore.configure do |config|
      # Uncomment for debugging
      # config.logger = ::Logger.new($stdout)
      config.default_response_format = :json
      config.request_exceptions = {
        bad_request: NotImplementedError,
        unauthorized: SecurityError,
        forbidden: NameError,
        not_found: LoadError,
        unprocessable: RuntimeError
      }
      config.response_formats = {
        csv: { disposition: "attachment", type: "text/csv; charset=UTF-8;", filename: "response.csv" },
        pdf: { disposition: "inline", type: "application/pdf", filename: "response.pdf" },
        json: { type: "application/json", format: :json },
        xml: { type: "application/xml", format: :xml },
        html: { type: "text/html", format: :html },
        text: { type: "text/plain", format: :text },
        nothing: { content: nil, type: "text/html; charset=utf-8", format: :nothing }
      }
    end
  end
end
