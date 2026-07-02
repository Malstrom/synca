# frozen_string_literal: true

class SimulateMatchContract < Dry::Validation::Contract
  params do
    required(:user_id).filled(:integer)
    required(:other_user_id).filled(:integer)
  end

  rule(:user_id, :other_user_id) do
    if values[:user_id].to_s == values[:other_user_id].to_s
      key(:other_user_id).failure("user_id and other_user_id must be different")
    end
  end
end
