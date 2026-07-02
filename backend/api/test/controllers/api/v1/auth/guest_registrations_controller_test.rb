# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class GuestRegistrationsControllerTest < ActionDispatch::IntegrationTest
        test "POST /api/v1/auth/guest with valid email creates guest user" do
          email = "new_guest@example.com"
          post api_v1_auth_guest_path, params: { auth: { email: email } }
          assert_response :created
          assert_equal "guest", response.parsed_body["account_type"]
          assert_not_nil response.parsed_body["access_token"]
        end

        test "POST /api/v1/auth/guest with existing guest email returns existing user" do
          user = users(:guest_user)
          post api_v1_auth_guest_path, params: { auth: { email: user.email } }
          assert_response :created
          assert_equal user.id, User.find_by(email: user.email).id
        end

        test "POST /api/v1/auth/guest with existing active email returns error" do
          user = users(:alice)
          post api_v1_auth_guest_path, params: { auth: { email: user.email } }
          assert_response :unprocessable_entity
          assert_equal "Email already active", response.parsed_body["error"]
        end

        test "POST /api/v1/auth/guest without email returns error" do
          post api_v1_auth_guest_path, params: { auth: { email: nil } }
          assert_response :unprocessable_entity
          assert_equal "Email is required", response.parsed_body["error"]
        end
      end
    end
  end
end
