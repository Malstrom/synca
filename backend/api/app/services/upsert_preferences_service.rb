# frozen_string_literal: true

class UpsertPreferencesService
  def initialize(user)
    @user = user
  end

  def call(params)
    preference_profile = PreferenceProfile.find_or_initialize_by(user: @user)
    preference_profile.assign_attributes(params[:preferences])

    if preference_profile.save
      Success(preference_profile)
    else
      Failure([:validation_failed, preference_profile.errors.full_messages.join(', ')])
    end
  end
end
