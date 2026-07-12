# frozen_string_literal: true

require "test_helper"

class ActivateAccountServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
    @user.update!(
      magic_link_token: "valid_token",
      magic_link_sent_at: Time.current
    )
  end

  test "activate with valid token and display_name" do
    result = ActivateAccountService.call(token: "valid_token", display_name: "New Display Name")

    assert result.success?
    assert_equal @user, result.value!

    @user.reload
    assert_equal "active", @user.account_type
    assert_equal "New Display Name", @user.profile.display_name
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
  end

  test "activate with expired token" do
    @user.update!(magic_link_sent_at: Settings.magic_link.ttl_hours.hours.ago - 1.hour)

    result = ActivateAccountService.call(token: "valid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_expired, I18n.t("services.activate_account.token_expired")], result.failure
  end

  test "activate with already used token" do
    @user.update!(magic_link_token: nil)

    result = ActivateAccountService.call(token: "valid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_already_used, I18n.t("services.activate_account.token_already_used")], result.failure
  end

  test "activate with already active account" do
    @user.update!(account_type: :active)

    result = ActivateAccountService.call(token: "valid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.activate_account.account_already_active")], result.failure
  end

  test "activate with invalid token" do
    result = ActivateAccountService.call(token: "invalid_token", display_name: "New Display Name")

    assert result.failure?
    assert_equal [:token_not_found, I18n.t("services.activate_account.token_not_found")], result.failure
  end
end