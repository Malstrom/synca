# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user, token)
    @user = user
    @token = token
    mail(to: user.email, subject: I18n.t("guest_mailer.magic_link.subject"))
  end
end
