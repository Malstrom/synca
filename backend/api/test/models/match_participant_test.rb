# frozen_string_literal: true

require "test_helper"

class MatchParticipantTest < ActiveSupport::TestCase
  test "valid participant" do
    assert match_participants(:alice_initiator).valid?
  end

  test "invalid without role" do
    mp = match_participants(:alice_initiator)
    mp.role = nil
    assert_not mp.valid?
  end

  test "duplicate user in same match is invalid" do
    mp = MatchParticipant.new(
      match: matches(:alice_bob_match),
      user:  users(:alice),
      role:  :member
    )
    assert_not mp.valid?
    assert mp.errors[:user_id].any?
  end
end
