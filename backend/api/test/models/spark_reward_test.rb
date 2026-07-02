# frozen_string_literal: true

require "test_helper"

# SparkReward model is intentionally thin: enums + associations + scope only.
# Written exclusively by SparkScoringJob — no contract needed.
class SparkRewardTest < ActiveSupport::TestCase
  test "valid reward" do
    assert spark_rewards(:alice_reward).valid?
  end

  test "active scope returns pending non-expired rewards" do
    assert_includes SparkReward.active, spark_rewards(:alice_reward)
  end

  test "active scope excludes expired rewards" do
    r = spark_rewards(:alice_reward)
    r.update_columns(valid_until: 1.day.ago)
    assert_not_includes SparkReward.active, r
  end

  test "reward_type enum maps correctly" do
    r = spark_rewards(:alice_reward)
    assert_includes SparkReward.reward_types.keys, r.reward_type
  end
end
