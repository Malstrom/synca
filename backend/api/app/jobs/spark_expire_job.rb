# frozen_string_literal: true

# Transitions stale pending/active Sparks to expired.
# Scheduled to run every minute via Solid Queue recurring tasks.
# limits_concurrency ensures only one run at a time globally.
class SparkExpireJob < ApplicationJob
  queue_as :spark
  limits_concurrency to: 1, key: -> { "spark_expire" }

  def perform
    ExpireStaleSparkService.call
  end
end
