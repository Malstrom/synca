# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  # --- success paths ---

  test "generates a magic link token for a valid user" do
    result = MagicLinkService.call(user: @user)

    assert_pattern { result => Success }
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "updates magic_link_sent_at when generating a new token" do
    original_sent_at = @user.magic_link_sent_at = 1.hour.ago
    @user.save!

    result = MagicLinkService.call(user: @user)

    assert_pattern { result => Success }
    assert_not_equal original_sent_at, @user.reload.magic_link_sent_at
  end

  # --- failure paths ---

  test "returns failure when user is not found" do
    result = MagicLinkService.call(user: nil)

    assert_pattern { result => Failure[:not_found, _] }
  end

  test "returns failure when user is rate limited" do
    @user.magic_link_sent_at = Settings.magic_link.rate_limit_minutes.minutes.ago
    @user.save!

    result = MagicLinkService.call(user: @user)

    assert_pattern { result => Failure[:rate_limited, _] }
  end

  # --- token validation ---

  test "validates a non-expired token" do
    @user.magic_link_token = "valid_token"
    @user.magic_link_sent_at = Time.current
    @user.save!

    result = MagicLinkService.validate_token(user: @user, token: "valid_token")

    assert_pattern { result => Success }
  end

  test "returns failure when token is expired" do
    @user.magic_link_token = "expired_token"
    @user.magic_link_sent_at = Settings.magic_link.ttl_hours.hours.ago
    @user.save!

    result = MagicLinkService.validate_token(user: @user, token: "expired_token")

    assert_pattern { result => Failure[:token_expired, _] }
  end

  test "returns failure when token is invalid" do
    @user.magic_link_token = "valid_token"
    @user.magic_link_sent_at = Time.current
    @user.save!

    result = MagicLinkService.validate_token(user: @user, token: "invalid_token")

    assert_pattern { result => Failure[:invalid_token, _] }
  end

  test "returns failure when user is not found during validation" do
    result = MagicLinkService.validate_token(user: nil, token: "any_token")

    assert_pattern { result => Failure[:not_found, _] }
  end
end