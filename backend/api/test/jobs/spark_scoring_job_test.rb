# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:completed_spark)
    @guest_user = users(:guest_user)
    @spark.update!(initiator: @guest_user)
  end

  test "send magic link to guest user" do
    assert_enqueued_emails 1 do
      SparkScoringJob.perform_now(@spark)
    end

    assert_not_nil @guest_user.reload.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end

  test "do not send magic link to active user" do
    @guest_user.update!(account_type: "active")

    assert_no_enqueued_emails do
      SparkScoringJob.perform_now(@spark)
    end
  end
end