# frozen_string_literal: true

require "test_helper"

class RewardEngineTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @session = SparkSession.create!(
      initiator:         @alice,
      partner:           @bob,
      status:            :completed,
      started_at:        1.hour.ago,
      completed_at:      Time.current,
      initiator_answers: [ 1, 2, 3 ],
      partner_answers:   [ 4, 5, 6 ],
      compatibility_score: 80.0
    )
  end

  test "issues one reward per participant" do
    assert_difference "SparkReward.count", 2 do
      RewardEngine.call(@session)
    end
  end

  test "issues premium_week reward for free users" do
    RewardEngine.call(@session)

    alice_reward = SparkReward.find_by(user: @alice, spark_session: @session)
    assert_equal "premium_week", alice_reward.reward_type
  end

  test "reward has pending status" do
    RewardEngine.call(@session)

    alice_reward = SparkReward.find_by(user: @alice, spark_session: @session)
    assert_equal "pending", alice_reward.status
  end

  test "reward valid_until is 7 days from now for premium_week" do
    RewardEngine.call(@session)

    alice_reward = SparkReward.find_by(user: @alice, spark_session: @session)
    assert_in_delta 7.days.from_now, alice_reward.valid_until, 5.seconds
  end

  test "does not issue duplicate rewards when called twice" do
    RewardEngine.call(@session)

    assert_no_difference "SparkReward.count" do
      RewardEngine.call(@session)
    end
  end

  test "marks reward_issued flags on session" do
    RewardEngine.call(@session)

    @session.reload
    assert @session.reward_issued_initiator
    assert @session.reward_issued_partner
  end
end
