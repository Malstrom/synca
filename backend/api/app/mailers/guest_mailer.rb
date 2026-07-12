# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link_email(user)
    @user = user
    @magic_link_url = activate_url(token: user.magic_link_token)
    mail(to: user.email, subject: I18n.t("mailers.guest.magic_link.subject"))
  end
end