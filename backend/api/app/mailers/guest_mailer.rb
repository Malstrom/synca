# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @magic_link_url = "#{ENV['FRONTEND_URL']}/activate?token=#{user.magic_link_token}"

    mail(
      to: user.email,
      subject: I18n.t("guest_mailer.magic_link.subject")
    )
  end
end