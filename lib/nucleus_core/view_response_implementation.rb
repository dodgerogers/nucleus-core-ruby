module NucleusCore
  class ViewResponseImplementation < NucleusCore::Entity
    def initialize(format, attrs={})
      status = status_code(attrs[:status])

      super(attrs.merge!(format: format, status: status))
    end

    private

    def status_code(status=nil)
      status = Utils.status_code(status)

      status.zero? ? 200 : status
    end
  end
end
