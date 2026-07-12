# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "generate magic link for guest user" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_equal @user, result.value!

    @user.reload
    assert_not_nil @user.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "generate magic link for active user" do
    @user.update!(account_type: :active)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "generate magic link too soon" do
    @user.update!(magic_link_sent_at: Time.current)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end
end