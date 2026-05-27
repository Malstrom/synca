# frozen_string_literal: true

require "test_helper"

# Minimal controller that exposes render_not_found for testing
class NotFoundDummyController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render_not_found("Widget")
  end
end

class ApiResponseConcernTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      get "/dummy_not_found", to: "not_found_dummy#index"
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "render_not_found returns 404 with correct error payload" do
    get "/dummy_not_found"
    assert_response :not_found
    body = response.parsed_body
    assert_equal "not_found", body.dig("error", "code")
  end
end
