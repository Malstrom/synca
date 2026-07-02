# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::GuestRegistrationsControllerTest < ApiTestCase
  test "POST /api/v1/auth/guest creates guest user with valid email" do
    post api_v1_auth_guest_path,
         params: { auth: { email: "new_guest@example.com" } },
         as: :json
    assert_response :created
    body = response.parsed_body
    assert body.key?("access_token")
    assert_equal "guest", body["account_type"]
    assert_equal "Bearer", body["token_type"]
  end

  test "POST /api/v1/auth/guest returns same token for existing guest email" do
    email = "returning_guest@example.com"
    User.create!(email: email, auth_provider: :email, account_type: :guest)

    post api_v1_auth_guest_path,
         params: { auth: { email: email } },
         as: :json
    assert_response :created
    assert response.parsed_body.key?("access_token")
  end

  test "POST /api/v1/auth/guest returns 422 for active account email" do
    post api_v1_auth_guest_path,
         params: { auth: { email: users(:alice).email } },
         as: :json
    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_equal "email_already_active", body.dig("error", "code")
  end

  test "POST /api/v1/auth/guest returns 422 when email is missing" do
    post api_v1_auth_guest_path,
         params: { auth: {} },
         as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body.key?("error")
  end

  test "POST /api/v1/auth/guest does not require Authorization header" do
    post api_v1_auth_guest_path,
         params: { auth: { email: "anon@example.com" } },
         as: :json
    assert_response :created
  end
end
