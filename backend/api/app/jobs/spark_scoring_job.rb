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
      next unless participant.user.account_type_guest?

      case MagicLinkService.call(user: participant.user)
      in Success(user)
        GuestMailer.magic_link_email(user).deliver_later
      in Failure([:rate_limited, _])
        # Log but don't fail the job
        Rails.logger.info("Magic link not sent to #{participant.user.email}: rate limited")
      in Failure([:error, msg])
        # Log but don't fail the job
        Rails.logger.error("Failed to send magic link to #{participant.user.email}: #{msg}")
      end
    end
  end
end