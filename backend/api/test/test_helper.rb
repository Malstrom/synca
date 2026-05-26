require "simplecov"
SimpleCov.start "rails" do
  add_filter "/config/"
  add_filter "/test/"
  formatter SimpleCov::Formatter::HTMLFormatter
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

# Shared helpers for API integration tests
class ApiTestCase < ActionDispatch::IntegrationTest
  private

  def json
    JSON.parse(response.body, symbolize_names: true)
  end

  def auth_headers(user)
    token = JwtService.access_token(user)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" }
  end

  def post_json(path, params: {})
    post path, params: params.to_json, headers: { "Content-Type" => "application/json" }
  end
end
