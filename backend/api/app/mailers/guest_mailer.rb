# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @magic_link_url = Rails.application.routes.url_helpers.api_v1_auth_activate_url(token: user.magic_link_token, host: Rails.application.config.action_mailer.default_url_options[:host])

    mail(
      to: user.email,
      subject: "Activate your account"
    )
  end
end