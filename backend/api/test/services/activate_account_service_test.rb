# frozen_string_literal: true

require "test_helper"

class ActivateAccountServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
    @token = "valid_token"
    @user.update!(magic_link_token: @token, magic_link_sent_at: Time.current)
  end

  test "activate account" do
    result = ActivateAccountService.call(user: @user, token: @token, display_name: "Luca")

    assert result.success?
    assert_equal "active", @user.reload.account_type
    assert_nil @user.magic_link_token
    assert_nil @user.magic_link_sent_at
    assert_equal "Luca", @user.profile.display_name
  end

  test "expired token" do
    @user.update!(magic_link_sent_at: 73.hours.ago)

    result = ActivateAccountService.call(user: @user, token: @token, display_name: "Luca")

    assert result.failure?
    assert_equal [ :token_expired, "Token has expired" ], result.failure
  end

  test "already used token" do
    @user.update!(magic_link_token: nil)

    result = ActivateAccountService.call(user: @user, token: @token, display_name: "Luca")

    assert result.failure?
    assert_equal [ :token_already_used, "Token has already been used" ], result.failure
  end

  test "already active account" do
    @user.update!(account_type: "active")

    result = ActivateAccountService.call(user: @user, token: @token, display_name: "Luca")

    assert result.failure?
    assert_equal [ :invalid_user, "User must be a guest" ], result.failure
  end
end