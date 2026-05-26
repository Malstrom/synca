# frozen_string_literal: true

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/config/"
  add_filter "/test/"
  add_filter "/app/mailers/application_mailer.rb"
  add_filter "/app/jobs/application_job.rb"
  minimum_coverage 90
  formatter SimpleCov::Formatter::HTMLFormatter
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Parallelism disabled: SimpleCov cannot aggregate coverage across forked workers
    parallelize(workers: 1)
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
