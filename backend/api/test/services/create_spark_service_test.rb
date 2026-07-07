# frozen_string_literal: true

require "test_helper"

class CreateSparkServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "creates pending spark without location" do
    result = CreateSparkService.call(current_user: @user, attrs: {})
    assert result.success?, "expected Success, got #{result.inspect}"

    spark = result.value!
    assert_equal "pending", spark.status
    assert_nil spark.location_lat
    assert_nil spark.location_lng
  end

  test "creates pending spark with location lat/lng" do
    result = CreateSparkService.call(current_user: @user, attrs: { lat: 55.7558, lng: 37.6176 })
    assert result.success?, "expected Success, got #{result.inspect}"

    spark = result.value!
    assert_in_delta 55.7558, spark.location_lat, 0.0001
    assert_in_delta 37.6176, spark.location_lng, 0.0001
  end
end
