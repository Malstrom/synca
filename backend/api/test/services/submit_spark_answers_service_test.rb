# frozen_string_literal: true

require "test_helper"

class SubmitSparkAnswersServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "stores initiator answers and enqueues job when both answered" do
    spark = Spark.create!(
      initiator:         @alice,
      partner:           @bob,
      status:            :active,
      initiator_answers: [ 1, 2, 3 ]
    )

    assert_enqueued_with(job: SparkScoringJob, args: [ spark.id ]) do
      result = SubmitSparkAnswersService.call(
        current_user: @bob,
        spark:        spark,
        answers:      [ 4, 5, 6 ]
      )
      assert result.success?, "expected Success, got #{result.inspect}"
    end

    assert_equal [ 4, 5, 6 ], spark.reload.partner_answers
  end

  test "stores initiator answers but does not enqueue job when partner not answered" do
    spark = Spark.create!(
      initiator: @alice,
      partner:   @bob,
      status:    :active
    )

    assert_no_enqueued_jobs(only: SparkScoringJob) do
      result = SubmitSparkAnswersService.call(
        current_user: @alice,
        spark:        spark,
        answers:      [ 1, 2, 3 ]
      )
      assert result.success?, "expected Success, got #{result.inspect}"
    end

    assert_equal [ 1, 2, 3 ], spark.reload.initiator_answers
  end

  test "returns session_not_active when spark is not active" do
    spark = Spark.create!(initiator: @alice, partner: @bob, status: :pending)

    result = SubmitSparkAnswersService.call(
      current_user: @alice,
      spark:        spark,
      answers:      [ 1, 2, 3 ]
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :session_not_active, code
  end
end
