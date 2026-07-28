# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ApiTestCase
  setup do
    @guest = User.create!(email: "guest_to_activate@example.com", auth_provider: :email, account_type: :guest)
  end

  test "POST /api/v1/auth/activate upgrades the guest to active, sets a password, and returns tokens" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" }, auth: { password: "password123" } },
      headers: auth_headers(@guest)

    assert_response :ok
    assert json[:access_token].present?
    assert json[:refresh_token].present?
    assert_equal "guest_to_activate@example.com", json.dig(:user, :email)
    assert @guest.reload.active?
    assert_equal "New User", @guest.profile.display_name
    assert @guest.authenticate("password123")
  end

  test "activated account can then log in with the password it was activated with" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" }, auth: { password: "password123" } },
      headers: auth_headers(@guest)
    assert_response :ok

    post_json "/api/v1/auth/login",
      params: { auth: { email: "guest_to_activate@example.com", password: "password123" } }

    assert_response :ok
    assert json[:access_token].present?
  end

  test "POST /api/v1/auth/activate without a token returns 401" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" }, auth: { password: "password123" } }

    assert_response :unauthorized
  end

  test "POST /api/v1/auth/activate without a display_name returns 422" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "" }, auth: { password: "password123" } },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
    refute @guest.reload.active?
  end

  test "POST /api/v1/auth/activate without a password returns 422" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" }, auth: {} },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
    refute @guest.reload.active?
  end

  test "POST /api/v1/auth/activate with a short password returns 422" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" }, auth: { password: "short" } },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
    refute @guest.reload.active?
  end
end
