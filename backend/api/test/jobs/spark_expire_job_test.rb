# frozen_string_literal: true

require "test_helper"

class SparkExpireJobTest < ActiveJob::TestCase
  test "expires stale pending and active sparks" do
    stale_spark = Spark.create!(
      initiator:  users(:alice),
      status:     :pending,
      created_at: 20.minutes.ago
    )

    assert_changes -> { stale_spark.reload.status }, from: "pending", to: "expired" do
      SparkExpireJob.perform_now
    end
  end

  test "does not expire recent sparks" do
    recent_spark = Spark.create!(
      initiator:  users(:alice),
      status:     :pending,
      created_at: 2.minutes.ago
    )

    SparkExpireJob.perform_now

    assert_equal "pending", recent_spark.reload.status
  end

  test "does not expire already completed sparks" do
    completed_spark = Spark.create!(
      initiator:         users(:alice),
      partner:           users(:bob),
      status:            :completed,
      created_at:        20.minutes.ago,
      completed_at:      Time.current,
      initiator_answers: [],
      partner_answers:   []
    )

    SparkExpireJob.perform_now

    assert_equal "completed", completed_spark.reload.status
  end

  test "is enqueued on spark queue" do
    assert_equal "spark", SparkExpireJob.new.queue_name
  end
end
