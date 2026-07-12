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
    assert_not_nil @guest_user.reload.magic_link_token
    assert_not_nil @guest_user.magic_link_sent_at
  end

  test "generate magic link for active user" do
    result = MagicLinkService.call(user: @active_user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "rate limited magic link generation" do
    @guest_user.update!(magic_link_sent_at: 2.minutes.ago)

    result = MagicLinkService.call(user: @guest_user)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end

  test "activate with valid token" do
    @guest_user.generate_magic_link_token
    token = @guest_user.magic_link_token

    result = MagicLinkService.activate(token: token, display_name: "New Display Name")

    assert result.success?
    assert_equal "active", @guest_user.reload.account_type
    assert_equal "New Display Name", @guest_user.profile.display_name
    assert_nil @guest_user.magic_link_token
  end

  test "activate with expired token" do
    @guest_user.generate_magic_link_token
    token = @guest_user.magic_link_token
    @guest_user.update!(magic_link_sent_at: Settings.magic_link.ttl_hours.hours.ago)

    result = MagicLinkService.activate(token: token, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.magic_link.token_expired")], result.failure
  end

  test "activate with already used token" do
    @guest_user.generate_magic_link_token
    token = @guest_user.magic_link_token
    @guest_user.update!(magic_link_token: nil)

    result = MagicLinkService.activate(token: token, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.magic_link.token_expired")], result.failure
  end

  test "activate with already active account" do
    @active_user.generate_magic_link_token
    token = @active_user.magic_link_token

    result = MagicLinkService.activate(token: token, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "activate with invalid token" do
    result = MagicLinkService.activate(token: "invalid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:not_found, I18n.t("services.magic_link.not_found")], result.failure
  end
end