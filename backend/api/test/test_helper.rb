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

    # Pattern matching helper for dry-monads results.
    # Usage:
    #   assert_pattern { result => Success }
    #   assert_pattern { result => Success(health_summary) }
    #   assert_pattern { result => Failure[:validation_failed, _] }
    #   assert_pattern { result => Failure[:validation_failed, message] }
    def assert_pattern(&block)
      block.call
    rescue NoMatchingPatternError => e
      flunk "Pattern did not match: #{e.message}"
    end
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

    def post_json(path, params: {}, headers: {})
      post path,
        params: params.to_json,
        headers: { "Content-Type" => "application/json" }.merge(headers)
    end

    def put_json(path, params: {}, headers: {})
      put path,
        params: params.to_json,
        headers: { "Content-Type" => "application/json" }.merge(headers)
    end
end
