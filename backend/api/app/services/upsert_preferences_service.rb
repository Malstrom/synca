# frozen_string_literal: true

class UpsertPreferencesService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs:)
    preference_profile = current_user.preference_profile || current_user.build_preference_profile

    if preference_profile.assign_attributes(attrs).save
      Success(preference_profile)
    else
      Failure([ :validation_failed, preference_profile.errors.full_messages.first ])
    end
  end
end
