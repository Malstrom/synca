# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  queue_as :default

  def perform(spark)
    spark.calculate_scores!

    spark.participants.each do |participant|
      case MagicLinkService.call(user: participant.user)
      in Success(user)
        GuestMailer.with(user: user).magic_link.deliver_later
      in Failure([:invalid_record, _])
        Rails.logger.error("Failed to generate magic link for user #{participant.user.id}: #{_}")
      end
    end
  end
end