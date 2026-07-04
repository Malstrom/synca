# frozen_string_literal: true

class UpsertPreferencesContract < Dry::Validation::Contract
  params do
    optional(:preferences).hash do
      optional(:sleep_together_importance).value(:integer?)
      optional(:temperature_preference).value(:string?)
      optional(:movement_preference).value(:string?)
      optional(:rhythm_importance).value(:integer?)
      optional(:self_chronotype).value(:string?)
    end
  end

  rule(preferences: :sleep_together_importance) do |ctx|
    next unless ctx[:preferences]&.key?(:sleep_together_importance)

    value = ctx[:preferences][:sleep_together_importance]
    if value && (value < 1 || value > 5)
      key.failure("must be between 1 and 5")
    end
  end

  rule(preferences: :rhythm_importance) do |ctx|
    next unless ctx[:preferences]&.key?(:rhythm_importance)

    value = ctx[:preferences][:rhythm_importance]
    if value && (value < 1 || value > 5)
      key.failure("must be between 1 and 5")
    end
  end

  rule(preferences: :temperature_preference) do |ctx|
    next unless ctx[:preferences]&.key?(:temperature_preference)

    value = ctx[:preferences][:temperature_preference]
    valid_values = %w[cool warm no_preference]
    if value && !valid_values.include?(value)
      key.failure("must be one of: #{valid_values.join(', ')}")
    end
  end

  rule(preferences: :movement_preference) do |ctx|
    next unless ctx[:preferences]&.key?(:movement_preference)

    value = ctx[:preferences][:movement_preference]
    valid_values = %w[very_little moderate a_lot as_much_as_possible]
    if value && !valid_values.include?(value)
      key.failure("must be one of: #{valid_values.join(', ')}")
    end
  end

  rule(preferences: :self_chronotype) do |ctx|
    next unless ctx[:preferences]&.key?(:self_chronotype)

    value = ctx[:preferences][:self_chronotype]
    valid_values = %w[morning night depends]
    if value && !valid_values.include?(value)
      key.failure("must be one of: #{valid_values.join(', ')}")
    end
  end
end
