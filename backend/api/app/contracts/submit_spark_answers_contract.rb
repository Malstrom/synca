# frozen_string_literal: true

class SubmitSparkAnswersContract < Dry::Validation::Contract
  params do
    required(:spark).hash do
      required(:answers).array(:integer)
    end
  end
end
