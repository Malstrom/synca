# frozen_string_literal: true

class ActivateUserContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    required(:profile).schema do
      required(:display_name).filled(:string)
    end
  end
end