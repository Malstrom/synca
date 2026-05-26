require "test_helper"

class MatchTest < ActiveSupport::TestCase
  test "valid match" do
    assert matches(:alice_bob_match).valid?
  end

  test "invalid without compatibility_score" do
    m = matches(:alice_bob_match)
    m.compatibility_score = nil
    assert_not m.valid?
  end

  test "compatibility_score out of range" do
    m = matches(:alice_bob_match)
    m.compatibility_score = 101
    assert_not m.valid?

    m.compatibility_score = -1
    assert_not m.valid?
  end

  test "has participants" do
    m = matches(:alice_bob_match)
    assert_equal 2, m.match_participants.count
  end

  test "initiator helper returns initiator user" do
    m = matches(:alice_bob_match)
    assert_equal users(:alice), m.initiator
  end

  test "members helper excludes initiator" do
    m = matches(:alice_bob_match)
    assert_includes m.members, users(:bob)
    assert_not_includes m.members, users(:alice)
  end

  test "status enum works" do
    m = matches(:alice_bob_match)
    assert m.proposed?
    m.accepted!
    assert m.accepted?
  end
end
