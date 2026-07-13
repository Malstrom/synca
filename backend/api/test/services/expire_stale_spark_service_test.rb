# frozen_string_literal: true

require "test_helper"

class ExpireStaleSparkServiceTest < ActiveSupport::TestCase
  test "expires a stale spark" do
    spark = sparks(:stale_pending_spark)

    ExpireStaleSparkService.call

    assert spark.reload.expired?
  end

  test "does not expire a completed spark" do
    spark = sparks(:alice_spark)

    ExpireStaleSparkService.call

    assert spark.reload.completed?
  end

  test "does not expire a recent pending spark" do
    spark = sparks(:recent_pending_spark)

    ExpireStaleSparkService.call

    assert spark.reload.pending?
  end
end
