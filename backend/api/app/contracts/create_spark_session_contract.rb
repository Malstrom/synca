# frozen_string_literal: true

class CreateSparkSessionContract < Dry::Validation::Contract
  params do
    optional(:spark_session).hash do
      optional(:lat).maybe(:float)
      optional(:lng).maybe(:float)
    end
  end
end
