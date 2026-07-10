# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  def perform(spark)
    # ... existing code ...

    RewardEngine.call(spark)

    [ spark.initiator, spark.partner ].each do |user|
      next unless user.account_type == "guest"
      result = MagicLinkService.call(user: user)
      next if result.failure?
      GuestMailer.magic_link(user, result.value!).deliver_later
    end
  end
end
