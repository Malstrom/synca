# frozen_string_literal: true

require "test_helper"

class ResendMagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link" do
    result = ResendMagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "rate limited" do
    @user.update!(magic_link_sent_at: Time.current)

    result = ResendMagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [ :rate_limited, "Please wait 5 minutes before requesting a new link" ], result.failure
  end
end
