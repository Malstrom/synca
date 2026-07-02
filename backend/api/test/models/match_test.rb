# frozen_string_literal: true

require "test_helper"

# Match model is intentionally thin: enum + associations + helpers only.
# Validation rules live at the service layer.
class MatchTest < ActiveSupport::TestCase
  test "valid match" do
    assert matches(:alice_bob_match).valid?
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
