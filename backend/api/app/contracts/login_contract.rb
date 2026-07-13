# frozen_string_literal: true

# Validates login params before authentication.
# Called internally by LoginService — never instantiated in a controller.
class LoginContract < Dry::Validation::Contract
  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

  params do
    required(:auth).hash do
      required(:email).filled(:string)
      required(:password).filled(:string)
    end
  end

  rule(auth: :email) do
    next if schema_error?(:auth)
    key.failure(I18n.t("contracts.errors.email.format")) unless EMAIL_REGEXP.match?(value)
  end

  rule(auth: :password) do
    next if schema_error?(:auth)
    min = Rails.application.config_for(:settings)["auth"]["min_password_length"]
    key.failure(I18n.t("contracts.errors.password.min_size")) if value.length < min
  end
end
