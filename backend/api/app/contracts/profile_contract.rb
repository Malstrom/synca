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

  VALID_GENDERS = %w[male female non_binary other].freeze

  rule(profile: :display_name) do
    key.failure("must be 50 characters or less") if value.length > 50
  end

  rule(profile: :bio) do
    next unless value
    key.failure("must be 300 characters or less") if value.length > 300
  end

  rule(profile: :gender) do
    next unless value
    key.failure("must be male, female, non_binary or other") unless VALID_GENDERS.include?(value)
  end

  rule(profile: :photo_urls) do
    next unless value
    key.failure("cannot have more than 6 photos") if value.length > 6
  end
end
