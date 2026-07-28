# frozen_string_literal: true

class ClaimEmailContract < Dry::Validation::Contract
  EMAIL_REGEXP = URI::MailTo::EMAIL_REGEXP

  params do
    required(:auth).hash do
      required(:email).filled(:string)
    end
  end

  rule(auth: :email) do
    next if schema_error?(:auth)
    key.failure(I18n.t("contracts.errors.email.format")) unless EMAIL_REGEXP.match?(value)
  end
end
