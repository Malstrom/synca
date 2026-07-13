# frozen_string_literal: true

class GuestMailer < ApplicationMailer
  include Rails.application.routes.url_helpers

  def magic_link_email(user)
    @user = user
    @magic_link = MagicLinkSerializer.new(user).serialize

    mail(
      to: @user.email,
      subject: I18n.t("guest_mailer.magic_link.subject")
    )
  end
end