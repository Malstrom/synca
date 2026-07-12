# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link(user)
    @user = user
    @token = user.magic_link_token
    @activate_url = activate_url(token: @token)

    mail(
      to: @user.email,
      subject: I18n.t("guest_mailer.magic_link.subject")
    )
  end
end