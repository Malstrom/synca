# frozen_string_literal: true

require "test_helper"

class Api::V1::MeControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
    @headers = auth_headers(@user)
  end

  test "GET /me returns user, profile and health summary" do
    get "/api/v1/me", headers: @headers

    assert_response :ok
    assert_equal @user.id,    json.dig(:user, :id)
    assert_equal @user.email, json.dig(:user, :email)
    assert json.key?(:profile)
    assert json.key?(:health_summary)
  end

  test "GET /me without token returns 401" do
    get "/api/v1/me"

    assert_response :unauthorized
  end

  test "GET /me returns null health_summary when not yet uploaded" do
    @user.health_summary&.destroy
    get "/api/v1/me", headers: @headers

    assert_response :ok
    assert_nil json[:health_summary]
  end

  test "GET /me returns null profile when not yet created" do
    @user.profile&.destroy
    get "/api/v1/me", headers: @headers

    assert_response :ok
    assert_nil json[:profile]
  end
end
