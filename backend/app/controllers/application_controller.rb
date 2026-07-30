class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :render_validation_error
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Api::Errors::ConflictError, with: :render_conflict

  private

  def render_api_error(code:, message:, status:, details: [])
    render json: {
      error: {
        code: code,
        message: message,
        details: Array(details)
      }
    }, status: status
  end

  def render_validation_error(error)
    message = error.message.sub(/: ([^:]+)\z/, " or invalid: \\1")

    render_api_error(
      code: "validation_error",
      message: message,
      status: 422
    )
  end

  def render_record_invalid(error)
    render_api_error(
      code: "validation_error",
      message: error.record.errors.full_messages.to_sentence,
      details: error.record.errors.map { |validation| validation.full_message },
      status: 422
    )
  end

  def render_not_found(error)
    render_api_error(
      code: "not_found",
      message: error.message,
      status: :not_found
    )
  end

  def render_conflict(error)
    render_api_error(
      code: error.code,
      message: error.message,
      details: error.details,
      status: :conflict
    )
  end
end