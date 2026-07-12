# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link
    @user = params[:user]
    @magic_link_url = params[:magic_link_url]
    mail(to: @user.email, subject: I18n.t("mailers.guest_mailer.magic_link.subject"))
  end
end
