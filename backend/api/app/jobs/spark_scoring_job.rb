# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  queue_as :spark

  def perform(spark_id)
    spark = Spark.find_by(id: spark_id)
    return unless spark
    return if spark.completed?

    initiator_health = spark.initiator.health_summary
    partner_health   = spark.partner.health_summary

    compatibility_result = if initiator_health && partner_health
      CompatibilityService.call(initiator_health, partner_health)
    else
      CompatibilityService::Result.new(
        total: 50.0, sleep: 50.0, activity: 50.0, lifestyle: 50.0, preferences: 50.0
      )
    end

    spark.update!(
      status:              :completed,
      completed_at:        Time.current,
      compatibility_score: compatibility_result.total
    )

    RewardEngine.call(spark)

    case MagicLinkService.call(user: spark.initiator)
    in Success(_)
      # Magic link sent successfully
    in Failure([:rate_limited, _])
      # Skip: rate limited
    in Failure([:already_active, _])
      # Skip: account already active
    in Failure([:error, msg])
      Rails.logger.error("Failed to send magic link: #{msg}")
    end

    case MagicLinkService.call(user: spark.partner)
    in Success(_)
      # Magic link sent successfully
    in Failure([:rate_limited, _])
      # Skip: rate limited
    in Failure([:already_active, _])
      # Skip: account already active
    in Failure([:error, msg])
      Rails.logger.error("Failed to send magic link: #{msg}")
    end
  end
end
