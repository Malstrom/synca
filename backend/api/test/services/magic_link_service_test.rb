# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest)
    @active_user = users(:active)
  end

  test "call generates magic link token for guest user" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "call fails for active user" do
    result = MagicLinkService.call(user: @active_user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "call fails when magic link sent recently" do
    @user.update!(magic_link_sent_at: 4.minutes.ago)
    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end

  test "activate activates user with valid token" do
    @user.generate_magic_link_token!
    result = MagicLinkService.new.activate(token: @user.magic_link_token, display_name: "New Name")

    assert result.success?
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_equal "New Name", @user.profile.display_name
  end

  test "activate fails with invalid token" do
    result = MagicLinkService.new.activate(token: "invalid", display_name: "New Name")

    assert result.failure?
    assert_equal [:token_not_found, I18n.t("services.magic_link.token_not_found")], result.failure
  end

  test "activate fails with expired token" do
    @user.update!(
      magic_link_token: SecureRandom.urlsafe_base64(32),
      magic_link_sent_at: MagicLinkService::TOKEN_TTL.ago - 1.hour
    )
    result = MagicLinkService.new.activate(token: @user.magic_link_token, display_name: "New Name")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.magic_link.token_expired")], result.failure
  end

  test "activate fails for already active user" do
    result = MagicLinkService.new.activate(token: @active_user.magic_link_token, display_name: "New Name")

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end
end
