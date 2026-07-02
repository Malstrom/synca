# frozen_string_literal: true

require "test_helper"

class CreateSparkSessionServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user = users(:alice)
  end

  test "creates pending spark session without location" do
    result = CreateSparkSessionService.call(current_user: @user, attrs: {})
    assert result.success?, "expected Success, got #{result.inspect}"

    session = result.value!
    assert_equal "pending", session.status
    assert_nil session.location_lat
    assert_nil session.location_lng
  end

  test "creates pending spark session with location lat/lng" do
    result = CreateSparkSessionService.call(current_user: @user, attrs: { lat: 55.7558, lng: 37.6176 })
    assert result.success?, "expected Success, got #{result.inspect}"

    session = result.value!
    assert_in_delta 55.7558, session.location_lat, 0.0001
    assert_in_delta 37.6176, session.location_lng, 0.0001
  end
end
