# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GuestRegistrationContract < Dry::Validation::Contract
        params do
          required(:auth).schema do
            required(:email).filled(:string)
          end
        end
      end
    end
  end
end
