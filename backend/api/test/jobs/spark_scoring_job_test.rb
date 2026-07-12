# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:in_progress_spark)
    @initiator = @spark.initiator
    @partner = @spark.partner
    @initiator.update!(account_type: :guest)
    @partner.update!(account_type: :guest)
  end

  test "should complete spark and send magic links to guests" do
    assert_enqueued_emails 2 do
      SparkScoringJob.perform_now(@spark.id)
    end

    @spark.reload
    assert_equal "completed", @spark.status
    assert_not_nil @spark.completed_at
    assert_not_nil @spark.compatibility_score

    @initiator.reload
    assert_not_nil @initiator.magic_link_token
    assert_not_nil @initiator.magic_link_sent_at

    @partner.reload
    assert_not_nil @partner.magic_link_token
    assert_not_nil @partner.magic_link_sent_at
  end

  test "should handle magic link sending failure gracefully" do
    # Simulate a failure in the mailer
    GuestMailer.stub(:magic_link_email, ->(_) { raise "Mailer error" }) do
      assert_no_enqueued_emails do
        SparkScoringJob.perform_now(@spark.id)
      end
    end

    @spark.reload
    assert_equal "completed", @spark.status
    assert_not_nil @spark.completed_at
    assert_not_nil @spark.compatibility_score

    @initiator.reload
    assert_not_nil @initiator.magic_link_token
    assert_not_nil @initiator.magic_link_sent_at

    @partner.reload
    assert_not_nil @partner.magic_link_token
    assert_not_nil @partner.magic_link_sent_at
  end
end
