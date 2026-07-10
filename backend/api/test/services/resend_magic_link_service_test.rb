# frozen_string_literal: true

require "test_helper"

class ResendMagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "resends magic link" do
    result = ResendMagicLinkService.call(email: @user.email)

    assert_pattern { result => Success }
    assert result.success?
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "fails with rate limit" do
    @user.update!(magic_link_sent_at: 1.minute.ago)
    result = ResendMagicLinkService.call(email: @user.email)

    assert_pattern { result => Failure[:rate_limit_exceeded, _] }
    assert result.failure?
  end
end

---