# frozen_string_literal: true

class ResendMagicLinkContract < Dry::Validation::Contract
  params do
    required(:email).filled(:string)
  end

  rule(:email) do
    key.failure(I18n.t("contracts.errors.email.blank")) if values[:email].blank?
    key.failure(I18n.t("contracts.errors.email.invalid")) unless values[:email] =~ URI::MailTo::EMAIL_REGEXP
  end
end