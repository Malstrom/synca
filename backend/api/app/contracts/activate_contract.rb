# frozen_string_literal: true

class ActivateContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    required(:profile).schema do
      required(:display_name).filled(:string)
    end
  end

  rule(:token) do
    key.failure(I18n.t("contracts.errors.token.invalid")) unless valid_token?(value)
  end

  rule(:profile) do
    key.failure(I18n.t("contracts.errors.profile.invalid")) unless valid_profile?(value)
  end

  private

    def valid_token?(token)
      user = User.find_by(magic_link_token: token)
      return false unless user

      user.magic_link_sent_at && user.magic_link_sent_at > 72.hours.ago
    end

    def valid_profile?(profile)
      profile[:display_name].present?
    end
end
