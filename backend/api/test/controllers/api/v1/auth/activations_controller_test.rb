# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ActivationsControllerTest < ApiTestCase
  setup do
    @guest = User.create!(email: "guest_to_activate@example.com", auth_provider: :email, account_type: :guest)
  end

  test "POST /api/v1/auth/activate upgrades the guest to active and returns tokens" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" } },
      headers: auth_headers(@guest)

    assert_response :ok
    assert json[:access_token].present?
    assert json[:refresh_token].present?
    assert_equal "guest_to_activate@example.com", json.dig(:user, :email)
    assert @guest.reload.active?
    assert_equal "New User", @guest.profile.display_name
  end

  test "POST /api/v1/auth/activate without a token returns 401" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "New User" } }

    assert_response :unauthorized
  end

  test "POST /api/v1/auth/activate without a display_name returns 422" do
    post_json "/api/v1/auth/activate",
      params: { profile: { display_name: "" } },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
    refute @guest.reload.active?
  end
end
