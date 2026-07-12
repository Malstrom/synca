# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link_email(user)
    @user = user
    @magic_link_url = activate_url(token: user.magic_link_token, host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(to: user.email, subject: I18n.t("guest_mailer.magic_link.subject"))
  end
end
