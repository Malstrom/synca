# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @session = SparkSession.create!(
      initiator:         @alice,
      partner:           @bob,
      status:            :active,
      started_at:        Time.current,
      initiator_answers: [ 1, 2, 3 ],
      partner_answers:   [ 4, 5, 6 ]
    )
  end

  test "performs scoring and transitions session to completed" do
    SparkScoringJob.perform_now(@session.id)

    @session.reload
    assert_equal "completed", @session.status
    assert @session.compatibility_score.present?
    assert @session.completed_at.present?
  end

  test "issues one reward per participant" do
    assert_difference "SparkReward.count", 2 do
      SparkScoringJob.perform_now(@session.id)
    end
  end

  test "sets reward_issued flags on session" do
    SparkScoringJob.perform_now(@session.id)

    @session.reload
    assert @session.reward_issued_initiator
    assert @session.reward_issued_partner
  end

  test "is enqueued on spark queue" do
    assert_equal "spark", SparkScoringJob.new.queue_name
  end

  test "does nothing when session does not exist" do
    assert_nothing_raised do
      SparkScoringJob.perform_now(-1)
    end
  end

  test "does nothing when session is already completed" do
    @session.update!(status: :completed, compatibility_score: 75.0, completed_at: Time.current)
    original_score = @session.compatibility_score

    SparkScoringJob.perform_now(@session.id)

    assert_equal original_score, @session.reload.compatibility_score
  end
end
