# frozen_string_literal: true

require "test_helper"

class ExpireStaleSparkServiceTest < ActiveSupport::TestCase
  test "expires a stale spark" do
    spark = sparks(:stale)

    ExpireStaleSparkService.call

    assert spark.reload.expired?
  end

  test "no-op when spark already expired" do
    spark = sparks(:expired)

    assert_no_difference "Spark.where(status: :expired).count" do
      ExpireStaleSparkService.call
    end

    assert spark.reload.expired?
  end

  test "does not expire a completed spark" do
    spark = sparks(:completed)

    ExpireStaleSparkService.call

    assert spark.reload.completed?
  end
end
