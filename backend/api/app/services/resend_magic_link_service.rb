# frozen_string_literal: true

class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(email:)
    user = User.find_by(email: email)

    if user && !user.active? && !rate_limited?(user)
      MagicLinkService.call(user: user)
      GuestMailer.magic_link_email(user).deliver_later
    end

    Success
  end

  private

  def rate_limited?(user)
    user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
  end
end