# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::RegistrationsControllerTest < ApiTestCase
  test "register with valid email and password returns 201 and tokens" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: "new@example.com", password: "password123", auth_provider: 0 } }

    assert_response :created
    assert json[:access_token].present?
    assert json[:refresh_token].present?
    assert_equal "new@example.com", json.dig(:user, :email)
  end

  test "register normalizes email to lowercase" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: "New@Example.COM", password: "password123", auth_provider: 0 } }

    assert_response :created
    assert_equal "new@example.com", json.dig(:user, :email)
  end

  test "register with duplicate email returns 422" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: users(:alice).email, password: "password123", auth_provider: 0 } }

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "register without email returns 422" do
    post_json "/api/v1/auth/register",
      params: { auth: { password: "password123", auth_provider: 0 } }

    assert_response :unprocessable_entity
  end

  test "register with password shorter than 8 chars returns 422" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: "short@example.com", password: "abc", auth_provider: 0 } }

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "register without auth_provider returns 422" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: "noprovider@example.com", password: "password123" } }

    assert_response :unprocessable_entity
  end
end
