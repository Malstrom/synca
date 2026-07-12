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
    spark.participants.each do |participant|
      next unless participant.user.guest?

      case MagicLinkService.call(user: participant.user)
      in Success(_)
        Rails.logger.info("Magic link sent to guest user #{participant.user.id}")
      in Failure([:rate_limited, _])
        Rails.logger.info("Magic link not sent to guest user #{participant.user.id} due to rate limiting")
      in Failure([:email_delivery_failed, _])
        Rails.logger.error("Failed to send magic link to guest user #{participant.user.id}")
      end
    end
  end
end
