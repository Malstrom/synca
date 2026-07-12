# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result, :do]

  def self.call(user:)
    new(user: user).call
  end

  def self.resend(user:)
    new(user: user).resend
  end

  def self.activate(token:, display_name:)
    new(token: token, display_name: display_name).activate
  end

  def initialize(user: nil, token: nil, display_name: nil)
    @user = user
    @token = token
    @display_name = display_name
  end

  def call
    user.generate_magic_link_token!

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:invalid_record, e.message])
  end

  def resend
    return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if rate_limited?

    user.generate_magic_link_token!

    Success(user)
  rescue ActiveRecord::RecordInvalid => e
    Failure([:invalid_record, e.message])
  end

  def activate
    user = User.includes(:profile).find_by!(magic_link_token: token)

    return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_expired?
    return Failure([:token_already_used, I18n.t("services.magic_link.token_already_used")]) if user.magic_link_token.nil?
    return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?

    user.activate!(display_name: display_name)

    Success(user)
  rescue ActiveRecord::RecordNotFound
    Failure([:not_found, I18n.t("services.magic_link.not_found")])
  rescue ActiveRecord::RecordInvalid => e
    Failure([:invalid_record, e.message])
  end

  private

  attr_reader :user, :token, :display_name

  def rate_limited?
    user.magic_link_sent_at&.> Settings.magic_link.rate_limit_minutes.minutes.ago
  end
end