# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link_email(user)
    @user = user
    @magic_link = magic_link_url(user.magic_link_token)
    mail(to: @user.email, subject: I18n.t("guest_mailer.magic_link_email.subject"))
  end

  private

  def magic_link_url(token)
    "#{Rails.application.config.action_mailer.default_url_options[:host]}/activate?token=#{token}"
  end
end