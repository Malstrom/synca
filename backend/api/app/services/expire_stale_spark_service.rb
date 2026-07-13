# frozen_string_literal: true

# Transitions all stale pending/active Sparks to expired.
# Called by SparkExpireJob — do not call directly from controllers.
#
# Uses find_each to ensure each Spark goes through a proper update
# rather than a raw SQL update_all, maintaining auditability and
# future hook points (e.g. push notifications on expiry).
#
# Idempotent: with_lock + re-check inside lock prevents double-expire
# on parallel runs or retries.
class ExpireStaleSparkService
  def self.call
    new.call
  end

  def call
    Spark.stale.find_each do |spark|
      spark.with_lock do
        next if spark.completed? || spark.expired?

        spark.update!(status: :expired)
      end
    end
  end
end
