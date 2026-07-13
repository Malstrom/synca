# frozen_string_literal: true

require "test_helper"

class SparkScoringServiceTest < ActiveSupport::TestCase
  setup do
    @initiator = users(:one)
    @partner   = users(:two)
    @spark     = sparks(:active)
  end

  test "no-op when spark not found" do
    assert_no_difference "Spark.count" do
      SparkScoringService.call(-1)
    end
  end

  test "no-op when spark already completed" do
    @spark.update!(status: :completed, completed_at: Time.current, compatibility_score: 80.0)

    assert_no_difference "SparkReward.count" do
      SparkScoringService.call(@spark.id)
    end
  end

  test "scores spark with compatibility result when health summaries present" do
    initiator_health = health_summaries(:one)
    partner_health   = health_summaries(:two)

    @spark.initiator.update!(health_summary: initiator_health)
    @spark.partner.update!(health_summary: partner_health)

    expected_score = CompatibilityService.call(initiator_health, partner_health).total

    SparkScoringService.call(@spark.id)

    @spark.reload
    assert @spark.completed?
    assert_in_delta expected_score, @spark.compatibility_score, 0.01
  end

  test "scores spark with fallback score when health summaries absent" do
    @spark.initiator.update!(health_summary: nil)
    @spark.partner.update!(health_summary: nil)

    SparkScoringService.call(@spark.id)

    @spark.reload
    assert @spark.completed?
    assert_equal Settings.spark.fallback_score, @spark.compatibility_score
  end

  test "calls RewardEngine after scoring" do
    RewardEngine.expects(:call).once
    SparkScoringService.call(@spark.id)
  end

  test "double call scores spark only once" do
    2.times { SparkScoringService.call(@spark.id) }

    @spark.reload
    assert @spark.completed?
    assert_equal 1, SparkReward.where(spark: @spark).count / 2
  end
end
