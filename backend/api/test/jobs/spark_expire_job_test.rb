# frozen_string_literal: true

require "test_helper"

class SparkExpireJobTest < ActiveJob::TestCase
  test "expires stale sparks" do
    spark = sparks(:stale_pending_spark)

    SparkExpireJob.perform_now

    assert spark.reload.expired?
  end
end
