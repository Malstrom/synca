# frozen_string_literal: true

module ApiResponse
  extend ActiveSupport::Concern

  def render_success(data, status: :ok)
    render json: data, status: status
  end

  def render_created(data)
    render json: data, status: :created
  end

  def render_error(code:, message:, field: nil, status: :unprocessable_entity)
    payload = { error: { code: code, message: message } }
    payload[:error][:field] = field if field
    render json: payload, status: status
  end

  def render_unauthorized(message: "Invalid or missing token")
    render_error(code: "unauthorized", message: message, status: :unauthorized)
  end

  def render_not_found(resource = "Resource")
    render_error(code: "not_found", message: "#{resource} not found", status: :not_found)
  end

  def render_validation_errors(record)
    first = record.errors.first
    render_error(
      code: "validation_failed",
      message: record.errors.full_messages.first,
      field: first&.attribute&.to_s,
      status: :unprocessable_entity
    )
  end

  # Renders the first error from a dry-validation contract result.
  # Extracts field name from the error path and message text.
  # Usage: return render_contract_errors(result) if result.failure?
  def render_contract_errors(result)
    error = result.errors.first
    field = error.path.reject { |k| k.is_a?(Integer) }.last&.to_s
    render_error(
      code: "validation_failed",
      message: error.text,
      field: field,
      status: :unprocessable_entity
    )
  end

  # Returns a standard auth payload with access + refresh tokens and basic user info.
  # Used by RegistrationsController and SessionsController after successful auth.
  def auth_response(user)
    {
      access_token:  JwtService.access_token(user),
      refresh_token: JwtService.refresh_token(user),
      user: {
        id:    user.id,
        email: user.email
      }
    }
  end
end
