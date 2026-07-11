# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:completed_spark)
    @initiator = @spark.initiator
    @partner = @spark.partner
  end

  test "sends magic link to guest users" do
    @initiator.update!(account_type: :guest)
    @partner.update!(account_type: :guest)

    assert_enqueued_emails 2 do
      SparkScoringJob.perform_now(@spark.id)
    end
  end

  test "does not send magic link to active users" do
    @initiator.update!(account_type: :active)
    @partner.update!(account_type: :active)

    assert_enqueued_emails 0 do
      SparkScoringJob.perform_now(@spark.id)
    end
  end
end