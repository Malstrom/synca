# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "generate magic link token for guest user" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil result.value!
    assert_equal @user.reload.magic_link_token, result.value!
    assert_not_nil @user.magic_link_sent_at
  end

  test "fail for non-guest user" do
    @user.update!(account_type: "active")

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [ :invalid_user, "User must be a guest" ], result.failure
  end
end
