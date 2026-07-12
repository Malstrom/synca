# frozen_string_literal: true

require "test_helper"

class MagicLinkServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:guest_user)
  end

  test "should generate magic link token for guest user" do
    result = MagicLinkService.call(user: @user)
    assert result.success?
    assert_not_nil @user.reload.magic_link_token
    assert_not_nil @user.magic_link_sent_at
  end

  test "should fail for active user" do
    @user.update!(account_type: :active)
    result = MagicLinkService.call(user: @user)
    assert result.failure?
    assert_equal [:account_already_active, I18n.t("services.magic_link.account_already_active")], result.failure
  end
end