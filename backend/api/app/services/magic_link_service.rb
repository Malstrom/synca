# frozen_string_literal: true

class MagicLinkService
  include Dry::Monads[:result, :do]
  include Rails.application.routes.url_helpers

  def self.call(user:)
    new(user: user).call
  end

  def self.activate(token:, profile:)
    new.activate(token: token, profile: profile)
  end

  def self.resend(email:)
    new.resend(email: email)
  end

  def initialize(user: nil)
    @user = user
  end

  def call
    user.generate_magic_link_token!

    GuestMailer.with(
      user: user,
      magic_link_url: activate_url(token: user.magic_link_token)
    ).magic_link.deliver_later

    Success(user)
  end

  def activate(token:, profile:)
    user = yield find_user_by_token(token: token)
    yield validate_user(user: user)
    yield validate_profile(profile: profile)

    user.update!(
      account_type: :active,
      magic_link_token: nil,
      magic_link_sent_at: nil
    )

    profile = user.profile || user.build_profile
    profile.update!(display_name: profile[:display_name])

    Success(user)
  end

  def resend(email:)
    user = yield find_user_by_email(email: email)
    yield validate_resend(user: user)

    user.generate_magic_link_token!

    GuestMailer.with(
      user: user,
      magic_link_url: activate_url(token: user.magic_link_token)
    ).magic_link.deliver_later

    Success(user)
  end

  private

    attr_reader :user

    def find_user_by_token(token:)
      user = User.includes(:profile).find_by(magic_link_token: token)
      return Failure([:not_found, I18n.t("services.magic_link.token_not_found")]) if user.nil?

      Success(user)
    end

    def find_user_by_email(email:)
      user = User.includes(:profile).find_by(email: email.downcase)
      Success(user || User.new(email: email.downcase))
    end

    def validate_user(user:)
      return Failure([:account_already_active, I18n.t("services.magic_link.account_already_active")]) if user.active?
      return Failure([:token_expired, I18n.t("services.magic_link.token_expired")]) if user.magic_link_expired?
      return Failure([:token_already_used, I18n.t("services.magic_link.token_already_used")]) if user.magic_link_already_used?

      Success(user)
    end

    def validate_profile(profile:)
      return Failure([:invalid_profile, I18n.t("services.magic_link.invalid_profile")]) unless profile.key?(:display_name)

      Success(profile)
    end

    def validate_resend(user:)
      return Failure([:rate_limited, I18n.t("services.magic_link.rate_limited")]) if user.magic_link_sent_at&.> Settings.magic_link.rate_limit_minutes.minutes.ago

      Success(user)
    end
end
