# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link(user, activate_url)
    @user = user
    @activate_url = activate_url

    mail(
      to: user.email,
      subject: I18n.t("guest_mailer.magic_link.subject")
    )
  end
end