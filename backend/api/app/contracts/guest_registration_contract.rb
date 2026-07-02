# frozen_string_literal: true

class GuestRegistrationContract < Dry::Validation::Contract
  params do
    required(:auth).hash do
      required(:email).filled(:string)
    end
  end
end
