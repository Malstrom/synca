# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @spark = sparks(:completed_spark)
    @initiator = @spark.initiator
    @partner = @spark.partner
  end

  test "should send magic link to guest participants" do
    @initiator.update!(account_type: :guest)
    @partner.update!(account_type: :guest)

    perform_enqueued_jobs do
      SparkScoringJob.perform_later(@spark.id)
    end

    assert_not_nil @initiator.reload.magic_link_token
    assert_not_nil @initiator.magic_link_sent_at
    assert_not_nil @partner.reload.magic_link_token
    assert_not_nil @partner.magic_link_sent_at
  end

  test "should not send magic link to active participants" do
    @initiator.update!(account_type: :active)
    @partner.update!(account_type: :active)

    perform_enqueued_jobs do
      SparkScoringJob.perform_later(@spark.id)
    end

    assert_nil @initiator.reload.magic_link_token
    assert_nil @initiator.magic_link_sent_at
    assert_nil @partner.reload.magic_link_token
    assert_nil @partner.magic_link_sent_at
  end

  test "should handle email delivery failure gracefully" do
    @initiator.update!(account_type: :guest)
    @partner.update!(account_type: :guest)

    # Stub the mailer to raise an error
    GuestMailer.stub(:magic_link_email, ->(_user) { raise "Email delivery failed" }) do
      perform_enqueued_jobs do
        SparkScoringJob.perform_later(@spark.id)
      end
    end

    assert_not_nil @initiator.reload.magic_link_token
    assert_not_nil @initiator.magic_link_sent_at
    assert_not_nil @partner.reload.magic_link_token
    assert_not_nil @partner.magic_link_sent_at
  end
end