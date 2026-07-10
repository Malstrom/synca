# frozen_string_literal: true

# Resends a magic link to a guest user.
# Returns Success() or Failure([:reason, detail]).
class ResendMagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(email:)
    user = User.find_by(email: email)
    return Success() unless user

    if user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
      return Failure([ :rate_limit_exceeded, "Please wait before requesting another link" ])
    end

    user.transaction do
      user.update!(
        magic_link_token: JwtService.encode_magic_link(user),
        magic_link_sent_at: Time.current
      )

      # TODO: Send email with magic link
      Success()
    end
  rescue ActiveRecord::RecordInvalid => e
    Failure([ :validation_failed, e.message ])
  end
end

---