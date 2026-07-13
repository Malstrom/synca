# frozen_string_literal: true

require "test_helper"

class SubmitSparkAnswersServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  def params_for(answers)
    { "spark" => { "answers" => answers } }
  end

  test "stores partner answers and enqueues scoring job when both answered" do
    spark = sparks(:active_awaiting_partner_answers)

    assert_enqueued_with(job: SparkScoringJob, args: [ spark.id ]) do
      result = SubmitSparkAnswersService.call(current_user: @bob, spark: spark, params: params_for([ 4, 5, 6 ]))
      assert result.success?, "expected Success, got #{result.inspect}"
    end

    assert_equal [ 4, 5, 6 ], spark.reload.partner_answers
  end

  test "stores initiator answers and does not enqueue job when partner has not answered" do
    spark = sparks(:active_no_answers)

    assert_no_enqueued_jobs(only: SparkScoringJob) do
      result = SubmitSparkAnswersService.call(current_user: @alice, spark: spark, params: params_for([ 1, 2, 3 ]))
      assert result.success?, "expected Success, got #{result.inspect}"
    end

    assert_equal [ 1, 2, 3 ], spark.reload.initiator_answers
  end

  test "returns session_not_active when spark is not active" do
    spark  = sparks(:alice_pending_spark)
    result = SubmitSparkAnswersService.call(current_user: @alice, spark: spark, params: params_for([ 1, 2, 3 ]))
    assert result.failure?
    assert_equal :session_not_active, result.failure.first
  end
end
