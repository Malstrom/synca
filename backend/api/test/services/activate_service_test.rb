# frozen_string_literal: true

require "test_helper"

class ActivateServiceTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @spark = sparks(:alice_pending_spark)
  end

  # --- success paths ---

  test "activates a pending spark" do
    result = ActivateService.call(user: @alice, spark: @spark)

    assert_pattern { result => Success }
    assert_equal "active", @spark.reload.status
    assert_not_nil @spark.started_at
  end

  test "returns the activated spark" do
    result = ActivateService.call(user: @alice, spark: @spark)

    assert_pattern { result => Success(spark) }
    assert_equal @spark, spark
  end

  # --- failure paths ---

  test "fails when spark is not pending" do
    active_spark = sparks(:active_no_answers)
    result = ActivateService.call(user: @alice, spark: active_spark)

    assert_pattern { result => Failure([:not_pending, _]) }
  end

  test "fails when user is not the initiator" do
    bob = users(:bob)
    result = ActivateService.call(user: bob, spark: @spark)

    assert_pattern { result => Failure([:not_initiator, _]) }
  end

  test "fails when spark is stale" do
    stale_spark = sparks(:stale_pending_spark)
    result = ActivateService.call(user: @alice, spark: stale_spark)

    assert_pattern { result => Failure([:stale, _]) }
  end

  # --- edge cases ---

  test "handles concurrent activation attempts" do
    # Simulate concurrent activation by updating the spark status directly
    @spark.update!(status: "active")

    result = ActivateService.call(user: @alice, spark: @spark)

    assert_pattern { result => Failure([:already_active, _]) }
  end

  test "preserves existing spark attributes" do
    original_attributes = @spark.attributes.except("status", "started_at")

    ActivateService.call(user: @alice, spark: @spark)

    @spark.reload
    assert_equal original_attributes, @spark.attributes.except("status", "started_at")
  end
end