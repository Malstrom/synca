# frozen_string_literal: true

require "test_helper"

class JoinSparkServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "joins pending spark with valid session_code" do
    spark = sparks(:alice_pending_spark)

    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      attrs:        { session_code: spark.session_code }
    )

    assert result.success?, "expected Success, got #{result.inspect}"

    joined = result.value!
    assert_equal @bob.id, joined.partner_id
    assert_equal "active", joined.status
    assert joined.started_at.present?
  end

  test "returns cannot_join_own_spark when initiator tries to join" do
    spark = sparks(:alice_pending_spark)

    result = JoinSparkService.call(
      current_user: @alice,
      spark:        spark,
      attrs:        { session_code: spark.session_code }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :cannot_join_own_spark, code
  end

  test "returns spark_not_joinable when spark is not pending" do
    spark = sparks(:alice_active_spark_for_join)

    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      attrs:        { session_code: spark.session_code }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :spark_not_joinable, code
  end

  test "returns invalid_code when code/token do not match" do
    spark = sparks(:alice_pending_spark)

    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      attrs:        { session_code: "000000" }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :invalid_code, code
  end
end
