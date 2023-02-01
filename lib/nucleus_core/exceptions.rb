class NucleusCore::BaseException < StandardError; end
class NucleusCore::NotAuthorized < NucleusCore::BaseException; end
class NucleusCore::NotFound < NucleusCore::BaseException; end
class NucleusCore::Unprocessable < NucleusCore::BaseException; end
class NucleusCore::BadRequest < NucleusCore::BaseException; end
