# frozen_string_literal: true

class ResendMagicLinkContract < Dry::Validation::Contract
  params do
    required(:email).filled(:string)
  end

  rule(:email) do
    key.failure(I18n.t("contracts.errors.email.blank")) if value.blank?
    key.failure(I18n.t("contracts.errors.email.invalid")) unless value =~ /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  end
end
