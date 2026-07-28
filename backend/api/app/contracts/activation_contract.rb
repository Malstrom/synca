# frozen_string_literal: true

class ActivationContract < Dry::Validation::Contract
  MIN_PASSWORD_LENGTH = Settings.auth.min_password_length

  params do
    required(:profile).hash do
      required(:display_name).filled(:string)
    end
    required(:auth).hash do
      required(:password).filled(:string)
    end
  end

  rule(auth: :password) do
    next if schema_error?(:auth)
    key.failure(I18n.t("contracts.errors.password.min_size")) if value.length < MIN_PASSWORD_LENGTH
  end
end
