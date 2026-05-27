# frozen_string_literal: true

# Transitions stale pending/active SparkSessions to expired.
# Scheduled to run every minute via Solid Queue recurring tasks.
class SparkExpireJob < ApplicationJob
  queue_as :spark

  def perform
    SparkSession.stale.update_all(status: SparkSession.statuses[:expired])
  end
end
