# frozen_string_literal: true

class ActivateContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    required(:profile).schema do
      required(:display_name).filled(:string)
    end
  end
end
