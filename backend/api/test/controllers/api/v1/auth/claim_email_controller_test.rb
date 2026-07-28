# frozen_string_literal: true

require "test_helper"

class Api::V1::Auth::ClaimEmailControllerTest < ApiTestCase
  setup do
    @guest = User.create!(auth_provider: :email, account_type: :guest)
  end

  test "POST /api/v1/auth/guest/claim_email attaches email to the current guest" do
    post_json "/api/v1/auth/guest/claim_email",
      params: { auth: { email: "claimed@example.com" } },
      headers: auth_headers(@guest)

    assert_response :ok
    assert_equal "claimed@example.com", json[:email]
    assert_equal @guest.id, json[:id]
    assert_equal "claimed@example.com", @guest.reload.email
  end

  test "POST /api/v1/auth/guest/claim_email without a token returns 401" do
    post_json "/api/v1/auth/guest/claim_email",
      params: { auth: { email: "claimed@example.com" } }

    assert_response :unauthorized
  end

  test "POST /api/v1/auth/guest/claim_email with an invalid email returns 422" do
    post_json "/api/v1/auth/guest/claim_email",
      params: { auth: { email: "not-an-email" } },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  test "POST /api/v1/auth/guest/claim_email with an already-taken email returns 422" do
    post_json "/api/v1/auth/guest/claim_email",
      params: { auth: { email: users(:alice).email } },
      headers: auth_headers(@guest)

    assert_response :unprocessable_entity
    assert_equal "email_taken", json.dig(:error, :code)
  end
end
