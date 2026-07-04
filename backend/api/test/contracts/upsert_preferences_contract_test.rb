# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  setup do
    @contract = UpsertPreferencesContract.new
  end

  test 'valid params' do
    params = {
      preferences: {
        sleep_together_importance: 4,
        temperature_preference: 'cool',
        movement_preference: 'moderate',
        rhythm_importance: 3,
        self_chronotype: 'night'
      }
    }
    result = @contract.call(params)
    assert result.success?
  end

  test 'invalid sleep_together_importance' do
    params = { preferences: { sleep_together_importance: 6 } }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences][:sleep_together_importance], 'must be one of: 1, 2, 3, 4, 5'
  end

  test 'invalid temperature_preference' do
    params = { preferences: { temperature_preference: 'invalid' } }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences][:temperature_preference], 'must be one of: cool, warm, no_preference'
  end

  test 'invalid movement_preference' do
    params = { preferences: { movement_preference: 'invalid' } }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences][:movement_preference],
                    'must be one of: very_little, moderate, a_lot, as_much_as_possible'
  end

  test 'invalid rhythm_importance' do
    params = { preferences: { rhythm_importance: 0 } }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences][:rhythm_importance], 'must be one of: 1, 2, 3, 4, 5'
  end

  test 'invalid self_chronotype' do
    params = { preferences: { self_chronotype: 'invalid' } }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences][:self_chronotype], 'must be one of: morning, night, depends'
  end

  test 'empty preferences' do
    params = { preferences: {} }
    result = @contract.call(params)
    assert_not result.success?
    assert_includes result.errors[:preferences], 'must contain at least one preference'
  end
end
