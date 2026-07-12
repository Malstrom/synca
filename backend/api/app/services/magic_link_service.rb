# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result]

  TOKEN_TTL = 72.hours

  def self.call(...) = new.call(...)

  def call(user:)
    user = user.class.includes(:profile).find(user.id)

    if user.account_type_active?
      Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")])
    else
      user.generate_magic_link_token
      Success(user)
    end
  end
end