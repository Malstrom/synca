# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:completed_spark)
    @guest_user = users(:guest_user)
    @spark.update!(initiator: @guest_user)
  end

  test "sends magic link to guest users" do
    assert_enqueued_emails 1 do
      SparkScoringJob.perform_now(@spark.id)
    end

    assert_not_nil @guest_user.reload.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end
end