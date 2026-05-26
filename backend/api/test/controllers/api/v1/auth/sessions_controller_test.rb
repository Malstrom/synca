# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::SessionsControllerTest < ApiTestCase
  setup do
    @user = users(:alice)
  end

  test "login with valid credentials returns 200 and tokens" do
    post_json "/api/v1/auth/login",
      params: { auth: { email: @user.email, password: "password" } }

    assert_response :ok
    assert json[:access_token].present?
    assert json[:refresh_token].present?
  end

  test "login with wrong password returns 401" do
    post_json "/api/v1/auth/login",
      params: { auth: { email: @user.email, password: "wrongpassword" } }

    assert_response :unauthorized
    assert_equal "invalid_credentials", json.dig(:error, :code)
  end

  test "login with unknown email returns 401" do
    post_json "/api/v1/auth/login",
      params: { auth: { email: "ghost@example.com", password: "password" } }

    assert_response :unauthorized
  end
end
