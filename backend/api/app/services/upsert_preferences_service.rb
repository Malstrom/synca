# frozen_string_literal: true

class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(current_user:, attrs:)
    new(current_user: current_user, attrs: attrs).call
  end

  def initialize(current_user:, attrs:)
    @current_user = current_user
    @attrs = attrs
  end

  def call
    preference_profile = PreferenceProfile.find_or_initialize_by(user: current_user)
    preference_profile.assign_attributes(attrs)
    return Failure[:validation_failed, preference_profile.errors.full_messages.join(", ")] unless preference_profile.save

    Success(preference_profile)
  end

  private

  attr_reader :current_user, :attrs
end