# frozen_string_literal: true

class GuestRegistrationContract < Dry::Validation::Contract
  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

  params do
    required(:auth).hash do
      optional(:email).maybe(:string)
      optional(:phone).maybe(:string)
      optional(:password).maybe(:string)
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

  rule(:auth) do
    next unless value[:email].nil? || value[:email].strip.empty?
    next unless value[:phone].nil? || value[:phone].strip.empty?
    key.failure("email or phone is required")
  end
end
