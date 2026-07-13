# frozen_string_literal: true

require "test_helper"

class CreateSparkServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "creates pending spark without location" do
    result = CreateSparkService.call(current_user: @user, params: { "spark" => {} })
    assert result.success?, "expected Success, got #{result.inspect}"
    assert_equal "pending", result.value!.status
    assert_nil result.value!.location_lat
  end

  test "creates pending spark with location lat/lng" do
    result = CreateSparkService.call(
      current_user: @user,
      params: { "spark" => { "lat" => 55.7558, "lng" => 37.6176 } }
    )
    assert result.success?, "expected Success, got #{result.inspect}"
    assert_in_delta 55.7558, result.value!.location_lat, 0.0001
    assert_in_delta 37.6176, result.value!.location_lng, 0.0001
  end
end
