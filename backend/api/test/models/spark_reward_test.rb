# frozen_string_literal: true

require "test_helper"

class SparkRewardTest < ActiveSupport::TestCase
  test "valid reward" do
    assert spark_rewards(:alice_reward).valid?
  end

  test "invalid without reward_type" do
    r = spark_rewards(:alice_reward)
    r.reward_type = nil
    assert_not r.valid?
  end

  test "invalid without valid_until" do
    r = spark_rewards(:alice_reward)
    r.valid_until = nil
    assert_not r.valid?
  end

  test "active scope returns pending non-expired rewards" do
    assert_includes SparkReward.active, spark_rewards(:alice_reward)
  end

  test "active scope excludes expired rewards" do
    r = spark_rewards(:alice_reward)
    r.update_columns(valid_until: 1.day.ago)
    assert_not_includes SparkReward.active, r
  end
end
