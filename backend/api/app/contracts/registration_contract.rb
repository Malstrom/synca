# frozen_string_literal: true

class RegistrationContract < Dry::Validation::Contract
  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

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
    key.failure("is not a valid email") unless EMAIL_REGEXP.match?(value)
  end

  rule(auth: :password) do
    next if schema_error?(:auth)
    next unless value
    key.failure("must be at least 8 characters") if value.length < 8
  end

  rule(auth: :auth_provider) do
    next if schema_error?(:auth)
    valid = User.auth_providers.key?(value.to_s) || User.auth_providers.value?(value.to_i)
    key.failure("is not a valid auth provider") unless valid
  end

  rule(:auth) do
    next if schema_error?(:auth)
    auth = values.to_h[:auth]
    provider = auth[:auth_provider]
    is_email_provider = User.auth_providers.key?("email") &&
                        (provider.to_s == "email" || provider.to_i == User.auth_providers["email"])
    next unless is_email_provider
    key([:auth, :email]).failure("is required for email auth provider") if auth[:email].blank?
  end
end
