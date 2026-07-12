# frozen_string_literal: true

require "test_helper"

class GuestMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:guest_user)
    @user.update!(
      magic_link_token: "test_token",
      magic_link_sent_at: Time.current
    )
  end

  test "magic_link_email" do
    email = GuestMailer.magic_link_email(@user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [@user.email], email.to
    assert_equal I18n.t("guest_mailer.magic_link_email.subject"), email.subject
    assert_match "test_token", email.body.to_s
  end
end