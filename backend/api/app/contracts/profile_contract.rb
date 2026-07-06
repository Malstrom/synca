# frozen_string_literal: true

class ProfileContract < Dry::Validation::Contract
  params do
    required(:profile).hash do
      required(:display_name).filled(:string)
      optional(:bio).maybe(:string)
      optional(:city).maybe(:string)
      optional(:gender).maybe(:string)
      optional(:birth_date).maybe(:date)
      optional(:photo_url_main).maybe(:string)
      optional(:photo_urls).maybe(:array)
    end
  end

  rule(profile: :gender) do
    next if schema_error?(:profile)
    next unless value
    key.failure("is not included in the list") unless Profile.genders.key?(value)
  end

  rule(profile: :display_name) do
    next if schema_error?(:profile)
    next unless value

    max = Settings.profile.display_name.max_length
    key.failure("is too long (maximum #{max} characters)") if value.length > max
  end

  rule(profile: :bio) do
    next if schema_error?(:profile)
    next unless value

    max = Settings.profile.bio.max_length
    key.failure("is too long (maximum #{max} characters)") if value.length > max
  end

  rule(profile: :photo_urls) do
    next if schema_error?(:profile)
    next unless value

    max = Settings.profile.photo_urls.max_count
    key.failure("too many photos (maximum #{max})") if value.length > max
  end
end
