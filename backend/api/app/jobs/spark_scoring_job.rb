# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  def perform(spark)
    RewardEngine.call(spark)

    spark.participants.each do |participant|
      user = participant.user

      if user.account_type == "guest"
        MagicLinkService.call(user: user).bind do |token|
          GuestMailer.magic_link(user, token).deliver_later
        end
      end
    end
  end
end
