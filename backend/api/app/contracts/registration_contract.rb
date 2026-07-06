# frozen_string_literal: true

class RegistrationContract < Dry::Validation::Contract
  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

  VALID_AUTH_PROVIDERS = User.auth_providers.keys.freeze

  params do
    required(:auth_provider).filled(:string)
    required(:auth).hash do
      optional(:email).maybe(:string)
      optional(:phone).maybe(:string)
      optional(:password).maybe(:string)
      optional(:provider_uid).maybe(:string)
    end
  end

  rule(:auth_provider) do
    key.failure("is not a valid auth provider") unless VALID_AUTH_PROVIDERS.include?(value)
  end

  rule(auth: :email) do
    next unless value
    key.failure("is not a valid email") unless EMAIL_REGEXP.match?(value)
  end

  rule(auth: :password) do
    next unless value
    key.failure("must be at least 8 characters") if value.length < 8
  end
end
