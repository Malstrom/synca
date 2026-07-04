# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  setup do
    @contract = UpsertPreferencesContract.new
  end

  test 'valid preferences' do
    result = @contract.call(preferences: {
                              sleep_together_importance: 3,
                              temperature_preference: 'cool',
                              movement_preference: 'moderate',
                              rhythm_importance: 4,
                              self_chronotype: 'night'
                            })
    assert result.success?
  end

  test 'invalid temperature_preference' do
    result = @contract.call(preferences: { temperature_preference: 'invalid' })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:temperature_preference], 'must be cool, warm or no_preference'
  end

  test 'invalid movement_preference' do
    result = @contract.call(preferences: { movement_preference: 'invalid' })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:movement_preference],
                    'must be very_little, moderate, a_lot or as_much_as_possible'
  end

  test 'invalid self_chronotype' do
    result = @contract.call(preferences: { self_chronotype: 'invalid' })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:self_chronotype], 'must be morning, night or depends'
  end

  test 'invalid sleep_together_importance' do
    result = @contract.call(preferences: { sleep_together_importance: 0 })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], 'must be between 1 and 5'

    result = @contract.call(preferences: { sleep_together_importance: 6 })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:sleep_together_importance], 'must be between 1 and 5'
  end

  test 'invalid rhythm_importance' do
    result = @contract.call(preferences: { rhythm_importance: 0 })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], 'must be between 1 and 5'

    result = @contract.call(preferences: { rhythm_importance: 6 })
    assert result.failure?
    assert_includes result.errors.to_h[:preferences][:rhythm_importance], 'must be between 1 and 5'
  end
end
