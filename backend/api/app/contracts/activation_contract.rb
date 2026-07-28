# frozen_string_literal: true

class ActivationContract < Dry::Validation::Contract
  params do
    required(:profile).hash do
      required(:display_name).filled(:string)
    end
  end
end
