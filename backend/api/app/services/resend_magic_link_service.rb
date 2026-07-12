# frozen_string_literal: true

class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(attrs:)
    user = User.find_by(email: attrs[:email])

    if user && user.guest? && (user.magic_link_sent_at.nil? || user.magic_link_sent_at < 5.minutes.ago)
      MagicLinkService.call(user: user)
      GuestMailer.magic_link_email(user).deliver_later
    end

    Success(nil)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end
end