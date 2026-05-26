require "test_helper"

class Api::V1::Auth::RegistrationsControllerTest < ApiTestCase
  test "register con credenziali valide restituisce 201 e token" do
    post_json "/api/v1/auth/register",
      params: { auth: { email: "new@example.com", password: "password123", auth_provider: 0 } }

    assert_response :created
    assert json[:access_token].present?
    assert json[:refresh_token].present?
    assert_equal "new@example.com", json.dig(:user, :email)
  end

  test "register con email duplicata restituisce 422" do
    existing = users(:one)

    post_json "/api/v1/auth/register",
      params: { auth: { email: existing.email, password: "password123", auth_provider: 0 } }

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "register senza email restituisce 422" do
    post_json "/api/v1/auth/register",
      params: { auth: { password: "password123", auth_provider: 0 } }

    assert_response :unprocessable_entity
  end
end
