# frozen_string_literal: true

class ResendMagicLinkContract < Dry::Validation::Contract
  params do
    required(:email).filled(:string)
  end
end