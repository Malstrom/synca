# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @guest_user = users(:guest_user)
    @active_user = users(:active_user)
  end

  test "generate magic link for guest user" do
    result = MagicLinkService.call(user: @guest_user)

    assert result.success?
    assert_not_nil result.value!.magic_link_token
    assert_not_nil result.value!.magic_link_sent_at
  end

  test "generate magic link for active user" do
    result = MagicLinkService.call(user: @active_user)

    assert result.failure?
    assert_equal [:account_already_active], result.failure
  end

  test "activate with valid token" do
    @guest_user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    result = MagicLinkService.activate(
      token: @guest_user.magic_link_token,
      display_name: "New Name"
    )

    assert result.success?
    user = result.value!
    assert_nil user.magic_link_token
    assert_equal :active, user.account_type
    assert_equal "New Name", user.profile.display_name
  end

  test "activate with expired token" do
    @guest_user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour
    )

    result = MagicLinkService.activate(
      token: @guest_user.magic_link_token,
      display_name: "New Name"
    )

    assert result.failure?
    assert_equal [:token_expired], result.failure
  end

  test "activate with already used token" do
    @guest_user.update!(
      magic_link_token: nil,
      magic_link_sent_at: Time.current
    )

    result = MagicLinkService.activate(
      token: @guest_user.magic_link_token,
      display_name: "New Name"
    )

    assert result.failure?
    assert_equal [:token_already_used], result.failure
  end

  test "activate with already active account" do
    @active_user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: Time.current
    )

    result = MagicLinkService.activate(
      token: @active_user.magic_link_token,
      display_name: "New Name"
    )

    assert result.failure?
    assert_equal [:account_already_active], result.failure
  end

  test "activate with invalid token" do
    result = MagicLinkService.activate(
      token: "invalid_token",
      display_name: "New Name"
    )

    assert result.failure?
    assert_equal [:token_not_found], result.failure
  end
end