# frozen_string_literal: true

require "test_helper"

class Api::V1::ProfileControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  # --- happy path ---

  test "PUT /me/profile updates existing profile and returns 200" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Alice Updated", bio: "New bio", city: "Milan" } },
      headers: @headers

    assert_response :ok
    assert_equal "Alice Updated", json.dig(:profile, :display_name)
    assert_equal "New bio",       json.dig(:profile, :bio)
    assert_equal "Milan",         json.dig(:profile, :city)
  end

  test "PUT /me/profile creates profile when it does not exist yet" do
    @user.profile.destroy

    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Brand New", birth_date: "1995-01-01", gender: "female" } },
      headers: @headers

    assert_response :ok
    assert_equal "Brand New", json.dig(:profile, :display_name)
  end

  test "PUT /me/profile with partial params only updates given fields" do
    original_bio = @user.profile.bio

    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Only Name Changed" } },
      headers: @headers

    assert_response :ok
    assert_equal "Only Name Changed", json.dig(:profile, :display_name)
    assert_equal original_bio,         json.dig(:profile, :bio)
  end

  test "PUT /me/profile updates photo_urls array" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Alice", photo_urls: [ "https://cdn.example.com/photo1.jpg" ] } },
      headers: @headers

    assert_response :ok
    assert_equal [ "https://cdn.example.com/photo1.jpg" ], json.dig(:profile, :photo_urls)
  end

  # --- validation errors ---

  test "PUT /me/profile with blank display_name returns 422" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "" } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/profile with display_name over 50 chars returns 422" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "A" * 51 } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/profile with bio over 300 chars returns 422" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Alice", bio: "B" * 301 } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "PUT /me/profile with more than 6 photo_urls returns 422" do
    put_json "/api/v1/me/profile",
      params: { profile: {
        display_name: "Alice",
        photo_urls: Array.new(7) { |index| "https://cdn.example.com/photo#{index}.jpg" }
      } },
      headers: @headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- auth ---

  test "PUT /me/profile without token returns 401" do
    put_json "/api/v1/me/profile",
      params: { profile: { display_name: "Alice" } }

    assert_response :unauthorized
  end
end
