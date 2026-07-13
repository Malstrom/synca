# frozen_string_literal: true

require "test_helper"

class SimulateMatchServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "returns Success with compatibility result when both users exist" do
    result = SimulateMatchService.call(
      params: { "user_a_id" => @alice.id, "user_b_id" => @bob.id }
    )
    assert result.success?, "expected Success, got #{result.inspect}"
    assert result.value!.total.is_a?(Numeric)
  end

  test "returns Failure(:not_found) when user does not exist" do
    result = SimulateMatchService.call(
      params: { "user_a_id" => 0, "user_b_id" => @bob.id }
    )
    assert result.failure?
    assert_equal :not_found, result.failure.first
  end
end
