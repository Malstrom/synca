# frozen_string_literal: true

require "test_helper"

class ActivateGuestServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
    @token = JwtService.encode(
      user_id: @user.id,
      purpose: 'activation',
      exp: 72.hours.from_now.to_i
    )
  end

  test "activate guest account successfully" do
    result = ActivateGuestService.call(token: @token, display_name: "Test User")

    assert result.success?
    assert_equal "active", @user.reload.account_type
    assert_equal "Test User", @user.profile.display_name
    assert_not_nil result.value!["access_token"]
    assert_not_nil result.value!["refresh_token"]
  end

  test "reject already used token" do
    @user.update!(magic_link_token: nil)
    result = ActivateGuestService.call(token: @token, display_name: "Test User")

    assert result.failure?
    assert_equal :token_already_used, result.failure.first
  end

  test "reject already active account" do
    @user.update!(account_type: 'active')
    result = ActivateGuestService.call(token: @token, display_name: "Test User")

    assert result.failure?
    assert_equal :account_already_active, result.failure.first
  end
end