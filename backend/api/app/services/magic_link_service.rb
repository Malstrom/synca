# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user:)
    user.generate_magic_link_token
    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:validation_failed, e.message])
  end
end