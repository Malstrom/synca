# frozen_string_literal: true

require "test_helper"

class SimulateMatchContractTest < ActiveSupport::TestCase
  test "valid when both user_id and other_user_id present and different" do
    result = SimulateMatchContract.new.call({ user_id: 1, other_user_id: 2 })
    assert result.success?, result.errors.to_h.inspect
  end

  test "invalid when user_id is missing" do
    result = SimulateMatchContract.new.call({ other_user_id: 2 })
    assert result.failure?
  end

  test "invalid when other_user_id is missing" do
    result = SimulateMatchContract.new.call({ user_id: 1 })
    assert result.failure?
  end

  test "invalid when user_id and other_user_id are the same" do
    result = SimulateMatchContract.new.call({ user_id: 1, other_user_id: 1 })
    assert result.failure?
  end
end
