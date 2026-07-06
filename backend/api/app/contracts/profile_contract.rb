# frozen_string_literal: true

class ProfileContract < Dry::Validation::Contract
  params do
    required(:profile).hash do
      required(:display_name).filled(:string, max_size?: Settings.profile.display_name.max_length)
      optional(:bio).maybe(:string, max_size?: Settings.profile.bio.max_length)
      optional(:city).maybe(:string)
      optional(:gender).maybe(:string, included_in?: Profile.genders.keys)
      optional(:birth_date).maybe(:date)
      optional(:photo_url_main).maybe(:string)
      optional(:photo_urls).maybe(:array, max_size?: Settings.profile.photo_urls.max_count)
    end
  end
end
