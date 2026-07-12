# frozen_string_literal: true

require "test_helper"

class GuestMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:guest)
    @user.generate_magic_link_token!
    @mail = GuestMailer.magic_link(@user)
  end

  test "magic link email" do
    assert_emails 1 do
      @mail.deliver_now
    end

    assert_equal [@user.email], @mail.to
    assert_equal I18n.t("guest_mailer.magic_link.subject"), @mail.subject
    assert_match @user.magic_link_token, @mail.body.encoded
  end
end
