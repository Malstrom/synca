# frozen_string_literal: true

require "test_helper"

class SparkExpireJobTest < ActiveJob::TestCase
  test "delegates to ExpireStaleSparkService" do
    ExpireStaleSparkService.expects(:call).once
    SparkExpireJob.perform_now
  end
end
