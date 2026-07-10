# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "generate valid magic link token" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil result.value!
    assert_equal @user.reload.magic_link_token, result.value!
  end
end