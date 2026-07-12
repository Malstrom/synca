# frozen_string_literal: true

class ActivateContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    required(:profile).schema do
      required(:display_name).filled(:string)
    end
  end

  rule(:token) do
    key.failure(I18n.t("contracts.errors.token.blank")) if values[:token].blank?
  end

  rule(:profile) do
    key.failure(I18n.t("contracts.errors.profile.blank")) if values[:profile].blank?
  end
end
