class Nucleus::BaseException < StandardError; end
class Nucleus::NotAuthorized < Nucleus::BaseException; end
class Nucleus::NotFound < Nucleus::BaseException; end
class Nucleus::Unprocessable < Nucleus::BaseException; end
class Nucleus::BadRequest < Nucleus::BaseException; end
