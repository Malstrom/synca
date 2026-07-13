# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/auth/login", type: :request do
  let(:password) { "secret123" }
  let!(:user)    { create(:user, email: "user@example.com", password: password) }

  def post_login(email: "user@example.com", pw: password)
    post "/api/v1/auth/login", params: { auth: { email: email, password: pw } }, as: :json
  end

  describe "success" do
    it "returns 200 with access_token and refresh_token" do
      post_login
      expect(response).to have_http_status(:ok)
      expect(json_body).to include("access_token", "refresh_token")
      expect(json_body.dig("user", "email")).to eq("user@example.com")
    end
  end

  describe "invalid credentials" do
    it "returns 401 when password is wrong" do
      post_login(pw: "wrongpassword")
      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("error", "code")).to eq("invalid_credentials")
    end

    it "returns 401 when user does not exist" do
      post_login(email: "nobody@example.com")
      expect(response).to have_http_status(:unauthorized)
      expect(json_body.dig("error", "code")).to eq("invalid_credentials")
    end
  end

  describe "validation" do
    it "returns 422 when email is missing" do
      post "/api/v1/auth/login", params: { auth: { password: password } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end

    it "returns 422 when password is missing" do
      post "/api/v1/auth/login", params: { auth: { email: "user@example.com" } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_body.dig("error", "code")).to eq("validation_failed")
    end
  end
end
