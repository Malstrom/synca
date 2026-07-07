# frozen_string_literal: true

require "test_helper"

class SparkScoringJobTest < ActiveJob::TestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @spark = Spark.create!(
      initiator:         @alice,
      partner:           @bob,
      status:            :active,
      started_at:        Time.current,
      initiator_answers: [ 1, 2, 3 ],
      partner_answers:   [ 4, 5, 6 ]
    )
  end

  test "performs scoring and transitions spark to completed" do
    SparkScoringJob.perform_now(@spark.id)

    @spark.reload
    assert_equal "completed", @spark.status
    assert @spark.compatibility_score.present?
    assert @spark.completed_at.present?
  end

  test "issues one reward per participant" do
    assert_difference "SparkReward.count", 2 do
      SparkScoringJob.perform_now(@spark.id)
    end
  end

  test "sets reward_issued flags on spark" do
    SparkScoringJob.perform_now(@spark.id)

    @spark.reload
    assert @spark.reward_issued_initiator
    assert @spark.reward_issued_partner
  end

  test "is enqueued on spark queue" do
    assert_equal "spark", SparkScoringJob.new.queue_name
  end

  test "does nothing when spark does not exist" do
    assert_nothing_raised do
      SparkScoringJob.perform_now(-1)
    end
  end

  test "does nothing when spark is already completed" do
    @spark.update!(status: :completed, compatibility_score: 75.0, completed_at: Time.current)
    original_score = @spark.compatibility_score

    SparkScoringJob.perform_now(@spark.id)

    assert_equal original_score, @spark.reload.compatibility_score
  end
end
