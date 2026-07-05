# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  def contract
    UpsertPreferencesContract.new
  end

  def valid_params
    {
      preferences: {
        sleep_together_importance: 3,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 4,
        self_chronotype: 'morning'
      }
    }
  end

  # --- happy path ---

  test 'valid params with all fields returns success' do
    result = contract.call(valid_params)
    assert result.success?
  end

  test 'valid params with only one field returns success' do
    result = contract.call({ preferences: { sleep_together_importance: 2 } })
    assert result.success?
  end

  test 'optional fields may be nil' do
    result = contract.call({ preferences: { sleep_together_importance: nil, temperature_preference: nil } })
    assert result.success?
  end

  # --- sleep_together_importance validation ---

  test 'sleep_together_importance below 1 returns failure' do
    result = contract.call({ preferences: { sleep_together_importance: 0 } })
    assert result.failure?
  end

  test 'sleep_together_importance above 5 returns failure' do
    result = contract.call({ preferences: { sleep_together_importance: 6 } })
    assert result.failure?
  end

  test 'sleep_together_importance 1 is valid' do
    result = contract.call({ preferences: { sleep_together_importance: 1 } })
    assert result.success?
  end

  test 'sleep_together_importance 5 is valid' do
    result = contract.call({ preferences: { sleep_together_importance: 5 } })
    assert result.success?
  end

  # --- temperature_preference validation ---

  test 'invalid temperature_preference returns failure' do
    result = contract.call({ preferences: { temperature_preference: 'invalid' } })
    assert result.failure?
  end

  test 'temperature_preference cool is valid' do
    result = contract.call({ preferences: { temperature_preference: 'cool' } })
    assert result.success?
  end

  test 'temperature_preference warm is valid' do
    result = contract.call({ preferences: { temperature_preference: 'warm' } })
    assert result.success?
  end

  test 'temperature_preference no_preference is valid' do
    result = contract.call({ preferences: { temperature_preference: 'no_preference' } })
    assert result.success?
  end

  # --- movement_preference validation ---

  test 'invalid movement_preference returns failure' do
    result = contract.call({ preferences: { movement_preference: 'invalid' } })
    assert result.failure?
  end

  test 'movement_preference very_little is valid' do
    result = contract.call({ preferences: { movement_preference: 'very_little' } })
    assert result.success?
  end

  test 'movement_preference moderate is valid' do
    result = contract.call({ preferences: { movement_preference: 'moderate' } })
    assert result.success?
  end

  test 'movement_preference a_lot is valid' do
    result = contract.call({ preferences: { movement_preference: 'a_lot' } })
    assert result.success?
  end

  test 'movement_preference as_much_as_possible is valid' do
    result = contract.call({ preferences: { movement_preference: 'as_much_as_possible' } })
    assert result.success?
  end

  # --- rhythm_importance validation ---

  test 'rhythm_importance below 1 returns failure' do
    result = contract.call({ preferences: { rhythm_importance: 0 } })
    assert result.failure?
  end

  test 'rhythm_importance above 5 returns failure' do
    result = contract.call({ preferences: { rhythm_importance: 6 } })
    assert result.failure?
  end

  test 'rhythm_importance 1 is valid' do
    result = contract.call({ preferences: { rhythm_importance: 1 } })
    assert result.success?
  end

  test 'rhythm_importance 5 is valid' do
    result = contract.call({ preferences: { rhythm_importance: 5 } })
    assert result.success?
  end

  # --- self_chronotype validation ---

  test 'invalid self_chronotype returns failure' do
    result = contract.call({ preferences: { self_chronotype: 'invalid' } })
    assert result.failure?
  end

  test 'self_chronotype morning is valid' do
    result = contract.call({ preferences: { self_chronotype: 'morning' } })
    assert result.success?
  end

  test 'self_chronotype night is valid' do
    result = contract.call({ preferences: { self_chronotype: 'night' } })
    assert result.success?
  end

  test 'self_chronotype depends is valid' do
    result = contract.call({ preferences: { self_chronotype: 'depends' } })
    assert result.success?
  end
end
