# frozen_string_literal: true

require 'test_helper'

class UpsertPreferencesContractTest < ActiveSupport::TestCase
  setup do
    @contract = UpsertPreferencesContract.new
  end

  test 'valid preferences' do
    result = @contract.call(preferences: {
                              sleep_together_importance: 3,
                              temperature_preference: 'warm',
                              movement_preference: 'a_lot',
                              rhythm_importance: 4,
                              self_chronotype: 'depends'
                            })

    assert_predicate result, :success?
  end

  test 'invalid sleep_together_importance' do
    result = @contract.call(preferences: { sleep_together_importance: 6 })

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences][:sleep_together_importance], 'must be one of: 1, 2, 3, 4, 5'
  end

  test 'invalid temperature_preference' do
    result = @contract.call(preferences: { temperature_preference: 'invalid' })

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences][:temperature_preference], 'must be one of: cool, warm, no_preference'
  end

  test 'invalid movement_preference' do
    result = @contract.call(preferences: { movement_preference: 'invalid' })

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences][:movement_preference],
                    'must be one of: very_little, moderate, a_lot, as_much_as_possible'
  end

  test 'invalid rhythm_importance' do
    result = @contract.call(preferences: { rhythm_importance: 0 })

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences][:rhythm_importance], 'must be one of: 1, 2, 3, 4, 5'
  end

  test 'invalid self_chronotype' do
    result = @contract.call(preferences: { self_chronotype: 'invalid' })

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences][:self_chronotype], 'must be one of: morning, night, depends'
  end

  test 'empty preferences' do
    result = @contract.call(preferences: {})

    assert_predicate result, :failure?
    assert_includes result.errors[:preferences], 'must contain at least one preference'
  end
end
