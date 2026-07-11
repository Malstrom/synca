# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:completed_spark)
    @initiator = @spark.initiator
    @partner = @spark.partner
  end

  test "enqueues magic link for guest users" do
    @initiator.update!(account_type: :guest)
    @partner.update!(account_type: :guest)

    assert_enqueued_with(job: GuestMailer, args: [@initiator, kind_of(String)]) do
      SparkScoringJob.perform_now(@spark.id)
    end

    assert_enqueued_with(job: GuestMailer, args: [@partner, kind_of(String)]) do
      SparkScoringJob.perform_now(@spark.id)
    end
  end

  test "does not enqueue magic link for active users" do
    @initiator.update!(account_type: :active)
    @partner.update!(account_type: :active)

    assert_no_enqueued_jobs do
      SparkScoringJob.perform_now(@spark.id)
    end
  end
end
