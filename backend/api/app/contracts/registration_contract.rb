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
    next unless value
    key.failure("is not a valid email") unless EMAIL_REGEXP.match?(value)
  end

  rule(auth: :password) do
    next unless value
    key.failure("must be at least 8 characters") if value.length < 8
  end

  rule(auth: :auth_provider) do
    provider = value.to_s
    key.failure("is not a valid auth provider") unless User.auth_providers.key?(provider)
  end
end
