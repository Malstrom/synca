# frozen_string_literal: true

class ActivateContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    required(:profile).schema do
      required(:display_name).filled(:string)
    end
  end

  rule(:token) do
    key.failure(I18n.t("contracts.errors.token.blank")) if value.blank?
  end

  rule("profile.display_name") do
    key.failure(I18n.t("contracts.errors.display_name.blank")) if value.blank?
  end
end