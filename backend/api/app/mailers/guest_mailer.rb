# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user, magic_link_url)
    @user = user
    @magic_link_url = magic_link_url

    mail(
      to: user.email,
      subject: I18n.t("guest_mailer.magic_link.subject")
    )
  end
end