# frozen_string_literal: true

require "test_helper"

class ProtectedDummyController < ApplicationController
  def index
    render json: { user_id: current_user.id }
  end
end

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      get "/dummy_protected", to: "protected_dummy#index"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "request without token returns 401" do
    get "/dummy_protected"
    assert_response :unauthorized
  end

  test "request with invalid token returns 401" do
    get "/dummy_protected", headers: { "Authorization" => "Bearer invalid.token.here" }
    assert_response :unauthorized
  end

  test "request with valid token returns 200 and current_user" do
    user = users(:bob)
    token = JwtService.access_token(user)
    get "/dummy_protected", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
    assert_equal user.id, response.parsed_body["user_id"]
  end

  test "malformed JWT token triggers rescue and returns 401" do
    # A syntactically valid-looking but cryptographically broken token
    # forces JWT::DecodeError inside authenticate_user!
    malformed = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.INVALIDSIG"
    get "/dummy_protected", headers: { "Authorization" => malformed }
    assert_response :unauthorized
  end
end
