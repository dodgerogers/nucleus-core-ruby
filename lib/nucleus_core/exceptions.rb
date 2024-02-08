module NucleusCore
  class BaseException < StandardError; end
  class BadRequest < NucleusCore::BaseException; end
  class UnAuthenticated < NucleusCore::BaseException; end
  class NotAuthorized < NucleusCore::BaseException; end
  class NotFound < NucleusCore::BaseException; end
  class Unprocessable < NucleusCore::BaseException; end
end
