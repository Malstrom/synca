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
    original_sent_at = @user.update!(magic_link_sent_at: 1.hour.ago).magic_link_sent_at
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
    @user.update!(magic_link_sent_at: Settings.magic_link.rate_limit_minutes.minutes.ago)
    result = MagicLinkService.call(user: @user)

    assert_pattern { result => Failure[:rate_limited, _] }
  end

  # --- token expiry ---

  test "token is considered expired after TTL" do
    @user.update!(
      magic_link_token: SecureRandom.uuid,
      magic_link_sent_at: Settings.magic_link.ttl_hours.hours.ago
    )

    assert @user.magic_link_expired?
  end

  test "token is not considered expired before TTL" do
    @user.update!(
      magic_link_token: SecureRandom.uuid,
      magic_link_sent_at: 1.hour.ago
    )

    refute @user.magic_link_expired?
  end
end