# frozen_string_literal: true

class ResendMagicLinkContract < Dry::Validation::Contract
  params do
    required(:email).filled(:string)
  end

  rule(:email) do
    key.failure(I18n.t("contracts.errors.email.invalid")) unless valid_email?(value)
  end

  private

    def valid_email?(email)
      email.match?(URI::MailTo::EMAIL_REGEXP)
    end
end
