module Api
  module Errors
    class ConflictError < StandardError
      attr_reader :code, :details

      def initialize(message = "Request conflicts with the current state", details: [], code: "registration_conflict")
        super(message)
        @details = details
        @code = code
      end
    end
  end
end
