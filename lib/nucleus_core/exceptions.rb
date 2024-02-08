module NucleusCore
  class BaseException < StandardError; end
  class BadRequest < BaseException; end
  class NotAuthenticated < BaseException; end
  class Unauthorized < BaseException; end
  class NotFound < BaseException; end
  class Unprocessable < BaseException; end
end
