# frozen_string_literal: true

# Transitions stale pending/active Sparks to expired.
# Scheduled to run every minute via Solid Queue recurring tasks.
class SparkExpireJob < ApplicationJob
  queue_as :spark

  def perform
    Spark.stale.update_all(status: Spark.statuses[:expired])
  end
end
