# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "generate magic link token" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil result.value!
    assert_not_nil @user.reload.magic_link_sent_at
  end
end