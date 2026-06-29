# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  def setup
    @initiator = users(:initiator)
    @partner   = users(:partner)

    @initiator_health = health_summaries(:initiator_current)
    @partner_health   = health_summaries(:partner_current)
  end

  test "completes session with compatibility score when both health summaries are present" do
    spark_session = SparkSession.create!(
      initiator_id: @initiator.id,
      partner_id:   @partner.id,
      status:       :active,
      session_code: "123456",
      qr_token:     SecureRandom.uuid
    )

    job = SparkScoringJob.new

    job.define_singleton_method(:reward_engine_call) do |session|
      RewardEngine.call(session)
    end

    SparkScoringJob.perform_now(spark_session.id)

    spark_session.reload

    assert_equal "completed", spark_session.status
    assert_not_nil spark_session.compatibility_score
  end

  test "expires session when initiator health summary is missing" do
    spark_session = SparkSession.create!(
      initiator_id: @initiator.id,
      partner_id:   @partner.id,
      status:       :active,
      session_code: "654321",
      qr_token:     SecureRandom.uuid
    )

    @initiator.health_summary.destroy

    SparkScoringJob.perform_now(spark_session.id)

    spark_session.reload

    assert_equal "expired", spark_session.status
    assert_nil spark_session.compatibility_score
  end

  test "expires session when partner health summary is missing" do
    spark_session = SparkSession.create!(
      initiator_id: @initiator.id,
      partner_id:   @partner.id,
      status:       :active,
      session_code: "111222",
      qr_token:     SecureRandom.uuid
    )

    @partner.health_summary.destroy

    SparkScoringJob.perform_now(spark_session.id)

    spark_session.reload

    assert_equal "expired", spark_session.status
    assert_nil spark_session.compatibility_score
  end

  test "does nothing when session is already completed" do
    spark_session = SparkSession.create!(
      initiator_id: @initiator.id,
      partner_id:   @partner.id,
      status:       :completed,
      session_code: "333444",
      qr_token:     SecureRandom.uuid,
      compatibility_score: 80.0,
      completed_at: Time.current
    )

    SparkScoringJob.perform_now(spark_session.id)

    spark_session.reload

    assert_equal "completed", spark_session.status
    assert_equal 80.0, spark_session.compatibility_score
  end

  test "returns silently when session not found" do
    assert_nothing_raised do
      SparkScoringJob.perform_now(-1)
    end
  end
end
