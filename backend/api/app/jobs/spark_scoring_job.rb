# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  include Dry::Monads[:result]

  def perform(spark_id)
    case SparkScoringService.call(spark_id: spark_id)
    in Success(_)
      # SparkScoringService already sent the magic link to the guest participant
    in Failure([:not_found, _])
      # Skip if spark not found
    end
  end
end