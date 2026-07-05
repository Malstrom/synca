# frozen_string_literal: true

class UpsertPreferencesService
  include Dry::Monads[:result]

  def call(user:, params:)
    preference_profile = PreferenceProfile.find_or_initialize_by(user: user)
    preference_profile.assign_attributes(params[:preferences])

    if preference_profile.save
      Success(preference_profile)
    else
      Failure([:validation_failed, preference_profile.errors.full_messages.join(', ')])
    end
  end
end
