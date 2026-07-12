# frozen_string_literal: true

class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_one :health_summary, dependent: :destroy
  has_one :preference_profile, dependent: :destroy

  enum account_type: { guest: 0, active: 1 }

  def generate_magic_link_token
    self.magic_link_token = SecureRandom.urlsafe_base64(32)
    self.magic_link_sent_at = Time.current
    save!
  end

  def magic_link_expired?
    magic_link_sent_at && magic_link_sent_at < 72.hours.ago
  end

  def activate!(display_name:)
    transaction do
      update!(account_type: :active)
      profile.update!(display_name: display_name)
      self.magic_link_token = nil
      save!
    end
  end
end