# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  def magic_link(user, token)
    @token = token
    @user  = user
    mail(to: user.email, subject: "Activate your Synca account")
  end
end