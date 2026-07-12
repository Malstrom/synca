# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @guest_user = users(:guest_user)
    @active_user = users(:active_user)
    @user_with_recent_token = users(:user_with_recent_token)
  end

  test "generate magic link for guest user" do
    result = MagicLinkService.call(user: @guest_user)

    assert result.success?
    @guest_user.reload
    assert_not_nil @guest_user.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end

  test "fail for active user" do
    result = MagicLinkService.call(user: @active_user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "rate limit magic link generation" do
    result = MagicLinkService.call(user: @user_with_recent_token)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end

  test "validate valid token" do
    @guest_user.generate_magic_link_token!
    result = MagicLinkService.validate_token(token: @guest_user.magic_link_token)

    assert result.success?
    assert_equal @guest_user, result.value!
  end

  test "validate expired token" do
    @guest_user.update!(
      magic_link_token: "expired_token",
      magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour
    )
    result = MagicLinkService.validate_token(token: "expired_token")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.magic_link.token_expired")], result.failure
  end

  test "validate invalid token" do
    result = MagicLinkService.validate_token(token: "invalid_token")

    assert result.failure?
    assert_equal [:token_not_found, I18n.t("services.magic_link.token_not_found")], result.failure
  end

  test "activate guest user" do
    result = MagicLinkService.activate(user: @guest_user, display_name: "New Display Name")

    assert result.success?
    @guest_user.reload
    assert_equal "active", @guest_user.account_type
    assert_nil @guest_user.magic_link_token
    assert_equal "New Display Name", @guest_user.profile.display_name
  end

  test "fail activation for active user" do
    result = MagicLinkService.activate(user: @active_user, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end
end
