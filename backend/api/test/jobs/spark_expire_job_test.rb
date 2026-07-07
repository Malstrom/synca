# frozen_string_literal: true

require "test_helper"

class SparkExpireJobTest < ActiveJob::TestCase
  test "expires stale pending and active sparks" do
    stale_spark = sparks(:stale_pending_spark)  # created_at: 20.minutes.ago

    assert_changes -> { stale_spark.reload.status }, from: "pending", to: "expired" do
      SparkExpireJob.perform_now
    end
  end

  test "does not expire recent sparks" do
    recent_spark = sparks(:recent_pending_spark)  # created_at: now

    SparkExpireJob.perform_now

    assert_equal "pending", recent_spark.reload.status
  end

  test "does not expire already completed sparks" do
    completed_spark = sparks(:alice_spark)  # status: completed

    SparkExpireJob.perform_now

    assert_equal "completed", completed_spark.reload.status
  end

  test "is enqueued on spark queue" do
    assert_equal "spark", SparkExpireJob.new.queue_name
  end
end
