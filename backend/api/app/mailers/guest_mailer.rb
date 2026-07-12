# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link_email(user)
    @user = user
    @magic_link = magic_link_url(user.magic_link_token)
    mail(to: @user.email, subject: "Activate your account")
  end

  private

  def magic_link_url(token)
    "#{Rails.application.routes.url_helpers.root_url}activate?token=#{token}"
  end
end