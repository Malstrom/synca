# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]
  include Rails.application.routes.url_helpers

  def self.call(...) = new(...).call

  def initialize(user:)
    @user = user
  end

  def call
    return Failure[:account_already_active] if @user.active?

    if @user.magic_link_sent_at&.> 5.minutes.ago
      return Failure[:rate_limited, I18n.t("services.magic_link.rate_limited")]
    end

    @user.generate_magic_link_token!

    GuestMailer.magic_link(@user).deliver_later
    Success(@user)
  rescue StandardError => e
    Failure[:error, e.message]
  end
end