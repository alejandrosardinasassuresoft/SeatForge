module Api
  module Errors
    class ValidationError < StandardError
      attr_reader :code, :details

      def initialize(message = "Validation failed", details: [], code: "validation_error")
        super(message)
        @details = details
        @code = code
      end
    end
  end
end
