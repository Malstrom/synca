# frozen_string_literal: true

class ResendMagicLinkService
  include Dry::Monads[:result]

  RATE_LIMIT = 5.minutes

  def self.call(...) = new.call(...)

  def call(attrs)
    user = User.find_by(email: attrs[:email])

    if user && user.magic_link_sent_at && user.magic_link_sent_at > RATE_LIMIT.ago
      return Failure([:rate_limited, I18n.t("resend_magic_link.rate_limited")])
    end

    if user
      case MagicLinkService.call(user: user)
      in Success(user)
        GuestMailer.magic_link_email(user).deliver_later
      in Failure(_)
        # Ignore failure to send email
      end
    end

    Success(nil)
  end
end