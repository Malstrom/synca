# frozen_string_literal: true

require "test_helper"

class RewardEngineTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @spark = sparks(:reward_pending_spark)  # completed, rewards not yet issued
  end

  test "issues one reward per participant" do
    assert_difference "SparkReward.count", 2 do
      RewardEngine.call(@spark)
    end
  end

  test "issues premium_week reward for free users" do
    RewardEngine.call(@spark)

    alice_reward = SparkReward.find_by(user: @alice, spark: @spark)
    assert_equal "premium_week", alice_reward.reward_type
  end

  test "reward has pending status" do
    RewardEngine.call(@spark)

    alice_reward = SparkReward.find_by(user: @alice, spark: @spark)
    assert_equal "pending", alice_reward.status
  end

  test "reward valid_until is 7 days from now for premium_week" do
    RewardEngine.call(@spark)

    alice_reward = SparkReward.find_by(user: @alice, spark: @spark)
    assert_in_delta 7.days.from_now, alice_reward.valid_until, 5.seconds
  end

  test "does not issue duplicate rewards when called twice" do
    RewardEngine.call(@spark)

    assert_no_difference "SparkReward.count" do
      RewardEngine.call(@spark)
    end
  end

  test "marks reward_issued flags on spark" do
    RewardEngine.call(@spark)

    @spark.reload
    assert @spark.reward_issued_initiator
    assert @spark.reward_issued_partner
  end
end
