# frozen_string_literal: true

class MagicLinkResendContract < Dry::Validation::Contract
  params do
    required(:email).filled(:string)
  end
end