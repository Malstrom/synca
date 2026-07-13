# frozen_string_literal: true

require "test_helper"

class JoinSparkServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "joins pending spark with valid session_code" do
    spark  = sparks(:alice_pending_spark)
    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      params:       { "spark" => { "session_code" => spark.session_code } }
    )
    assert result.success?, "expected Success, got #{result.inspect}"
    assert_equal @bob.id,  result.value!.partner_id
    assert_equal "active", result.value!.status
  end

  test "returns cannot_join_own_spark when initiator tries to join" do
    spark  = sparks(:alice_pending_spark)
    result = JoinSparkService.call(
      current_user: @alice,
      spark:        spark,
      params:       { "spark" => { "session_code" => spark.session_code } }
    )
    assert result.failure?
    assert_equal :cannot_join_own_spark, result.failure.first
  end

  test "returns spark_not_joinable when spark is not pending" do
    spark  = sparks(:alice_spark)
    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      params:       { "spark" => { "session_code" => spark.session_code } }
    )
    assert result.failure?
    assert_equal :spark_not_joinable, result.failure.first
  end

  test "returns invalid_code when code does not match" do
    spark  = sparks(:alice_pending_spark)
    result = JoinSparkService.call(
      current_user: @bob,
      spark:        spark,
      params:       { "spark" => { "session_code" => "000000" } }
    )
    assert result.failure?
    assert_equal :invalid_code, result.failure.first
  end
end
