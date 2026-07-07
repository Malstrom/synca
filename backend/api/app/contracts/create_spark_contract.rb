# frozen_string_literal: true

class CreateSparkContract < Dry::Validation::Contract
  params do
    optional(:spark).hash do
      optional(:lat).maybe(:float)
      optional(:lng).maybe(:float)
    end
  end
end
