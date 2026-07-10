# frozen_string_literal: true

require "test_helper"

class ResendMagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "resend magic link for guest user" do
    result = ResendMagicLinkService.call(email: @user.email)

    assert result.success?
    assert_equal I18n.t("magic_link.resent"), result.value!
  end

  test "rate limit resend attempts" do
    @user.update!(magic_link_sent_at: 2.minutes.ago)
    result = ResendMagicLinkService.call(email: @user.email)

    assert result.failure?
    assert_equal :rate_limited, result.failure.first
  end

  test "always return success for non-existent email" do
    result = ResendMagicLinkService.call(email: "nonexistent@example.com")

    assert result.success?
    assert_equal I18n.t("magic_link.resent"), result.value!
  end
end
