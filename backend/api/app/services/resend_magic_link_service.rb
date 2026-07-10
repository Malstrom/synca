# frozen_string_literal: true

# Handles resending magic links with rate limiting
class ResendMagicLinkService
  include Dry::Monads[:result]

  RATE_LIMIT = 5.minutes

  def self.call(...) = new.call(...)

  def call(email:)
    user = User.find_by(email: email)

    return Success(I18n.t('magic_link.resent')) unless user&.account_type == 'guest'

    if rate_limited?(user)
      Failure([:rate_limited, I18n.t('magic_link.rate_limited')])
    else
      generate_and_send_token(user)
      Success(I18n.t('magic_link.resent'))
    end
  end

  private

  def rate_limited?(user)
    user.magic_link_sent_at && user.magic_link_sent_at > RATE_LIMIT.ago
  end

  def generate_and_send_token(user)
    result = MagicLinkService.call(user: user)
    return if result.failure?

    # TODO: Implement email sending logic
  end
end
