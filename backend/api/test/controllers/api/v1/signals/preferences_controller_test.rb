# frozen_string_literal: true

require "test_helper"

class Api::V1::Signals::PreferencesControllerTest < ApiTestCase
  def setup
    @user = users(:alice)
    @headers = auth_headers(@user)
    @attrs = {
      sleep_together_importance: 3,
      temperature_preference: "cool",
      movement_preference: "moderate",
      rhythm_importance: 4,
      self_chronotype: "night"
    }
  end

  test "upserts preferences" do
    post_json "/api/v1/signals/preferences", params: { preferences: @attrs }, headers: @headers

    assert_response :success
    assert_equal @attrs[:sleep_together_importance], json[:preferences][:sleep_together_importance]
    assert_equal @attrs[:temperature_preference], json[:preferences][:temperature_preference]
    assert_equal @attrs[:movement_preference], json[:preferences][:movement_preference]
    assert_equal @attrs[:rhythm_importance], json[:preferences][:rhythm_importance]
    assert_equal @attrs[:self_chronotype], json[:preferences][:self_chronotype]
  end

  test "partial upsert" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: { sleep_together_importance: 3 } },
      headers: @headers

    assert_response :success
    assert_equal 3, json[:preferences][:sleep_together_importance]
    assert_nil json[:preferences][:temperature_preference]
    assert_nil json[:preferences][:movement_preference]
    assert_nil json[:preferences][:rhythm_importance]
    assert_nil json[:preferences][:self_chronotype]
  end

  test "validation failed" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: { sleep_together_importance: 6 } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json[:error][:code]
  end

  test "contract errors" do
    post_json "/api/v1/signals/preferences",
      params: { preferences: { temperature_preference: "invalid" } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "temperature_preference must be one of: cool, warm, no_preference", json[:error][:message]
  end

  test "unauthenticated" do
    post_json "/api/v1/signals/preferences", params: { preferences: @attrs }

    assert_response :unauthorized
  end
end
