# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    module Auth
      class SessionsControllerTest < ApiTestCase
        setup do
          @password = "secret123"
          @user = users(:alice)
          @user.update!(password: @password)
        end

        # POST /api/v1/auth/login

        test "returns 200 with tokens on valid credentials" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email, password: @password } },
               as: :json

          assert_response :ok
          assert json[:access_token].present?
          assert json[:refresh_token].present?
          assert_equal @user.email, json.dig(:user, :email)
        end

        test "returns 401 on wrong password" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email, password: "wrongpass" } },
               as: :json

          assert_response :unauthorized
          assert_equal "invalid_credentials", json.dig(:error, :code)
        end

        test "returns 401 when user does not exist" do
          post api_v1_auth_login_path,
               params: { auth: { email: "nobody@example.com", password: @password } },
               as: :json

          assert_response :unauthorized
          assert_equal "invalid_credentials", json.dig(:error, :code)
        end

        test "returns 422 when email is missing" do
          post api_v1_auth_login_path,
               params: { auth: { password: @password } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "validation_failed", json.dig(:error, :code)
        end

        test "returns 422 when password is missing" do
          post api_v1_auth_login_path,
               params: { auth: { email: @user.email } },
               as: :json

          assert_response :unprocessable_entity
          assert_equal "validation_failed", json.dig(:error, :code)
        end
      end
    end
  end
end
