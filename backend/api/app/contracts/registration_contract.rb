# frozen_string_literal: true

class RegistrationContract < Dry::Validation::Contract
  EMAIL_REGEXP        = URI::MailTo::EMAIL_REGEXP
  MIN_PASSWORD_LENGTH = Settings.auth.min_password_length

  params do
    required(:auth).hash do
      optional(:email).maybe(:string)
      optional(:phone).maybe(:string)
      optional(:password).maybe(:string)
      optional(:provider_uid).maybe(:string)
      required(:auth_provider).filled
    end
  end

  rule(auth: :email) do
    next if schema_error?(:auth)
    next unless value
    key.failure(I18n.t("contracts.errors.email.format")) unless EMAIL_REGEXP.match?(value)
  end

  rule(auth: :password) do
    next if schema_error?(:auth)
    next unless value
    key.failure(I18n.t("contracts.errors.password.min_size")) if value.length < MIN_PASSWORD_LENGTH
  end

  rule(auth: :auth_provider) do
    next if schema_error?(:auth)
    valid = User.auth_providers.key?(value.to_s) || User.auth_providers.value?(value.to_i)
    key.failure(I18n.t("contracts.errors.auth_provider.invalid")) unless valid
  end

  rule(:auth) do
    next if schema_error?(:auth)
    auth = values.to_h[:auth]
    provider = auth[:auth_provider]
    is_email_provider = User.auth_providers.key?("email") &&
                        (provider.to_s == "email" || provider.to_i == User.auth_providers["email"])
    next unless is_email_provider
    key([:auth, :email]).failure(I18n.t("contracts.errors.email.required")) if auth[:email].blank?
  end
end
