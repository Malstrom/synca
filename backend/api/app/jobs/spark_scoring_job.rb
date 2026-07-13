# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  queue_as :default

  def perform(spark_id:)
    spark = Spark.includes(:initiator, :partner).find(spark_id)

    case MagicLinkService.call(user: spark.initiator) if spark.initiator.guest?
    in Success(user)
      GuestMailer.magic_link_email(user).deliver_later
    in Failure([:rate_limited, _])
      Rails.logger.info("Magic link rate limited for user #{spark.initiator_id}")
    end

    case MagicLinkService.call(user: spark.partner) if spark.partner&.guest?
    in Success(user)
      GuestMailer.magic_link_email(user).deliver_later
    in Failure([:rate_limited, _])
      Rails.logger.info("Magic link rate limited for user #{spark.partner_id}")
    end
  end
end