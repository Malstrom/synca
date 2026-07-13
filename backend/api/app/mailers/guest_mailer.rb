# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @magic_link = "#{Settings.frontend_url}/activate?token=#{user.magic_link_token}"
    mail(to: @user.email, subject: "Activate your account")
  end
end
