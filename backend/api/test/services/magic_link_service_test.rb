# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest)
  end

  test "successful magic link generation" do
    result = MagicLinkService.call(user: @user)

    assert result.success?
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "account already active" do
    @user.update!(account_type: :active)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end

  test "rate limited" do
    @user.update!(magic_link_sent_at: 1.minute.ago)

    result = MagicLinkService.call(user: @user)

    assert result.failure?
    assert_equal [:rate_limited, I18n.t("services.magic_link.rate_limited")], result.failure
  end
end