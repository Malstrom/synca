# frozen_string_literal: true

require "test_helper"

class ActivateGuestServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
    @token = JwtService.encode_magic_link(@user)
    @user.update!(magic_link_token: @token)
  end

  test "activates guest account with valid token" do
    result = ActivateGuestService.call(token: @token, display_name: "Luca")

    assert_pattern { result => Success }
    assert result.success?
    assert_equal "active", @user.reload.account_type
    assert_equal "Luca", @user.profile.display_name
    assert_not_nil result.value![:access_token]
    assert_not_nil result.value![:refresh_token]
  end

  test "fails with already used token" do
    @user.update!(magic_link_token: nil)
    result = ActivateGuestService.call(token: @token, display_name: "Luca")

    assert_pattern { result => Failure[:token_already_used, _] }
    assert result.failure?
  end

  test "fails with expired token" do
    expired_token = JwtService.encode_magic_link(@user, exp: 1.hour.ago)
    result = ActivateGuestService.call(token: expired_token, display_name: "Luca")

    assert_pattern { result => Failure[:invalid_token, _] }
    assert result.failure?
  end
end

---