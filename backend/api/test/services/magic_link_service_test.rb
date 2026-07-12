# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "generate magic link for guest user" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil @user.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "generate magic link for active user" do
    @user.update!(account_type: :active)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "generate magic link too soon" do
    @user.update!(magic_link_sent_at: 4.minutes.ago)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end

  test "activate with valid token" do
    @user.generate_magic_link_token!
    display_name = "New Display Name"

    result = MagicLinkService.activate(token: @user.magic_link_token, display_name: display_name)

    assert result.success?
    @user.reload
    assert_equal "active", @user.account_type
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
    assert_equal display_name, @user.profile.display_name
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago, magic_link_token: SecureRandom.urlsafe_base64(32))

    result = MagicLinkService.activate(token: @user.magic_link_token, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.magic_link.token_expired")], result.failure
  end

  test "activate with already active account" do
    @user.update!(account_type: :active, magic_link_token: SecureRandom.urlsafe_base64(32))

    result = MagicLinkService.activate(token: @user.magic_link_token, display_name: "New Display Name")

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "activate with invalid token" do
    result = MagicLinkService.activate(token: "invalid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_not_found, I18n.t("services.magic_link.token_not_found")], result.failure
  end
end
