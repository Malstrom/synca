# frozen_string_literal: true

class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    user.class.includes(:profile).find(user.id)

    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      Failure([ :rate_limited, I18n.t("services.resend_magic_link.rate_limited") ])
    else
      token = MagicLinkService.call(user: user).value!
      GuestMailer.magic_link(user, token).deliver_later
      Success()
    end
  end
end