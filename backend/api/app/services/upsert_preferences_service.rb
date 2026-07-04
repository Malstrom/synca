# frozen_string_literal: true

# Upserts the PreferenceProfile for a given user.
# Returns Success(preference_profile) or Failure([:validation_failed, message]).
class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs:)
    preference_profile = PreferenceProfile.find_or_initialize_by(user: current_user)

    if preference_profile.update(attrs)
      Success(preference_profile)
    else
      Failure([ :validation_failed, preference_profile.errors.full_messages.first ])
    end
  end
end
