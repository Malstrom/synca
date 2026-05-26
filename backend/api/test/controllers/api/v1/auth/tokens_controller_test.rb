require "test_helper"

class Api::V1::Auth::TokensControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
  end

  test "refresh with valid token returns new access_token" do
    refresh_token = JwtService.refresh_token(@user)

    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: refresh_token } }

    assert_response :ok
    assert json[:access_token].present?
    refute json.key?(:refresh_token)
  end

  test "refresh with access_token instead of refresh_token returns 401" do
    access_token = JwtService.access_token(@user)

    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: access_token } }

    assert_response :unauthorized
    assert_equal "invalid_token", json.dig(:error, :code)
  end

  test "refresh with corrupted token returns 401" do
    post_json "/api/v1/auth/refresh",
      params: { auth: { refresh_token: "not.a.valid.token" } }

    assert_response :unauthorized
  end
end
