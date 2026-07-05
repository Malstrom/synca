# frozen_string_literal: true

class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs:)
    profile = PreferenceProfile.find_or_initialize_by(user: current_user)
    profile.assign_attributes(attrs)
    profile.save ? Success(profile) : Failure([:validation_failed, profile.errors.full_messages.first])
  end
end
