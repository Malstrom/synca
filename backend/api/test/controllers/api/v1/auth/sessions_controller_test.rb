# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class SessionsControllerTest < ActionDispatch::IntegrationTest
        setup do
          @password = "secret123"
          @user = users(:one)
          @user.update!(password: @password)
        end

        # POST /api/v1/auth/login

        test "returns 200 with tokens on valid credentials" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email, password: @password } },
               as: :json

          assert_response :ok
          assert_includes response.parsed_body.keys, "access_token"
          assert_includes response.parsed_body.keys, "refresh_token"
          assert_equal @user.email, response.parsed_body.dig("user", "email")
        end

        test "returns 401 on wrong password" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email, password: "wrongpass" } },
               as: :json

          assert_response :unauthorized
          assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
        end

        test "returns 401 when user does not exist" do
          post api_v1_auth_login_path,
               params: { auth: { email: "nobody@example.com", password: @password } },
               as: :json

          assert_response :unauthorized
          assert_equal "invalid_credentials", response.parsed_body.dig("error", "code")
        end

        test "returns 422 when email is missing" do
          post api_v1_auth_login_path,
               params: { auth: { password: @password } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "validation_failed", response.parsed_body.dig("error", "code")
        end

        test "returns 422 when password is missing" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "validation_failed", response.parsed_body.dig("error", "code")
        end
      end
    end
  end
end
