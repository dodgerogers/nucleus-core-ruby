# Rack::Utils patch for status code
class Utils
  HTTP_STATUS_CODES = {
    100 => "Continue",
    101 => "Switching Protocols",
    102 => "Processing",
    103 => "Early Hints",
    200 => "OK",
    201 => "Created",
    202 => "Accepted",
    203 => "Non-Authoritative Information",
    204 => "No Content",
    205 => "Reset Content",
    206 => "Partial Content",
    207 => "Multi-Status",
    208 => "Already Reported",
    226 => "IM Used",
    300 => "Multiple Choices",
    301 => "Moved Permanently",
    302 => "Found",
    303 => "See Other",
    304 => "Not Modified",
    305 => "Use Proxy",
    306 => "(Unused)",
    307 => "Temporary Redirect",
    308 => "Permanent Redirect",
    400 => "Bad Request",
    401 => "Unauthorized",
    402 => "Payment Required",
    403 => "Forbidden",
    404 => "Not Found",
    405 => "Method Not Allowed",
    406 => "Not Acceptable",
    407 => "Proxy Authentication Required",
    408 => "Request Timeout",
    409 => "Conflict",
    410 => "Gone",
    411 => "Length Required",
    412 => "Precondition Failed",
    413 => "Payload Too Large",
    414 => "URI Too Long",
    415 => "Unsupported Media Type",
    416 => "Range Not Satisfiable",
    417 => "Expectation Failed",
    421 => "Misdirected Request",
    422 => "Unprocessable Entity",
    423 => "Locked",
    424 => "Failed Dependency",
    425 => "Too Early",
    426 => "Upgrade Required",
    428 => "Precondition Required",
    429 => "Too Many Requests",
    431 => "Request Header Fields Too Large",
    451 => "Unavailable for Legal Reasons",
    500 => "Internal Server Error",
    501 => "Not Implemented",
    502 => "Bad Gateway",
    503 => "Service Unavailable",
    504 => "Gateway Timeout",
    505 => "HTTP Version Not Supported",
    506 => "Variant Also Negotiates",
    507 => "Insufficient Storage",
    508 => "Loop Detected",
    509 => "Bandwidth Limit Exceeded",
    510 => "Not Extended",
    511 => "Network Authentication Required"
  }.freeze

  SYMBOL_TO_STATUS_CODE = Hash[*HTTP_STATUS_CODES.map do |code, message|
    [message.downcase.gsub(/\s|-|'/, "_").to_sym, code]
  end.flatten]

  def self.status_code(status)
    if status.is_a?(Symbol)
      return SYMBOL_TO_STATUS_CODE.fetch(status) do
        raise ArgumentError, "Unrecognized status code #{status.inspect}"
      end
    end

    status.to_i
  end

  def self.wrap(object)
    return [] if object.nil?

    object.is_a?(Array) ? object : [object]
  end

  # Calling `return` in a block/proc returns from the outer calling scope as well.
  # Lambdas do not have this limitation. So we convert the proc returned
  # from a block method into a lambda to avoid 'return' exiting the method early.
  # https://stackoverflow.com/questions/2946603/ruby-convert-proc-to-lambda
  def self.capture(args=[], &block)
    proxy_object = Object.new
    proxy_object.define_singleton_method(:_proc_to_lambda_, &block)

    proxy_object.method(:_proc_to_lambda_).to_proc.call(*args)
  end

  def self.subclass?(entity, *classes)
    parent_classes = entity.class.ancestors.to_set
    parent_classes = entity.ancestors.to_set if entity.instance_of?(Class)

    parent_classes.intersect?(classes.to_set)
  end

  def self.to_const(string)
    Object.const_get(string)
  rescue StandardError
    nil
  end
end
