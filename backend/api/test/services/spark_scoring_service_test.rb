# frozen_string_literal: true

require "test_helper"

class SparkScoringServiceTest < ActiveSupport::TestCase
  setup do
    @spark = sparks(:active_both_answered)
  end

  test "no-op when spark not found" do
    assert_no_difference "Spark.where(status: :completed).count" do
      SparkScoringService.call(-1)
    end
  end

  test "no-op when spark already completed" do
    spark = sparks(:alice_spark)

    assert_no_difference "SparkReward.count" do
      SparkScoringService.call(spark.id)
    end
  end

  test "scores spark with fallback score when health summaries absent" do
    @spark.initiator.update!(health_summary: nil)
    @spark.partner.update!(health_summary: nil)

    SparkScoringService.call(@spark.id)

    @spark.reload
    assert @spark.completed?
    assert_equal Settings.spark.fallback_score, @spark.compatibility_score
  end

  test "issues rewards for both participants" do
    assert_difference "SparkReward.count", 2 do
      SparkScoringService.call(@spark.id)
    end
  end

  test "double call scores spark only once" do
    2.times { SparkScoringService.call(@spark.id) }

    assert_equal 2, SparkReward.where(spark: @spark).count
  end
end
