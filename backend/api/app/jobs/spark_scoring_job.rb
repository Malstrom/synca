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

    # Send magic link to guest participants
    [spark.initiator, spark.partner].each do |user|
      next unless user.guest?

      case MagicLinkService.call(user: user)
      in Success(_)
        # Do nothing, email sent
      in Failure([:email_failed, msg])
        Rails.logger.error("Failed to send magic link to #{user.email}: #{msg}")
      end
    end
  end
end