# frozen_string_literal: true

require "test_helper"

class SimulateMatchServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "returns Success with compatibility result when both users exist" do
    result = SimulateMatchService.call(user_id: @alice.id, other_user_id: @bob.id)
    assert result.success?, "expected Success, got #{result.inspect}"

    sim = result.value!
    assert sim.total.is_a?(Numeric)
  end

  test "returns Failure(:not_found) when user does not exist" do
    result = SimulateMatchService.call(user_id: 0, other_user_id: @bob.id)
    assert result.failure?, "expected Failure, got #{result.inspect}"

    code, _message = result.failure
    assert_equal :not_found, code
  end
end
