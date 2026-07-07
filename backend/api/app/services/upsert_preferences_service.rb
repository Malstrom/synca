# frozen_string_literal: true

# Upserts the PreferenceProfile for a given user.
# Returns Success(preference_profile) or Failure([:validation_failed, message]).
class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs:)
    preference_profile = current_user.preference_profile || current_user.build_preference_profile

    preference_profile.assign_attributes(attrs)
    if preference_profile.save
      Success(preference_profile)
    else
      Failure([ :validation_failed, preference_profile.errors.full_messages.first ])
    end
  end
end