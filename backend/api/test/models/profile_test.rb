# frozen_string_literal: true

require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "valid profile" do
    profile = profiles(:alice_profile)
    assert profile.valid?
  end

  test "invalid without display_name" do
    profile = profiles(:alice_profile)
    profile.display_name = nil
    assert_not profile.valid?
    assert profile.errors[:display_name].any?
  end

  test "display_name too long" do
    profile = profiles(:alice_profile)
    profile.display_name = "a" * 51
    assert_not profile.valid?
  end

  test "bio too long" do
    profile = profiles(:alice_profile)
    profile.bio = "x" * 301
    assert_not profile.valid?
  end

  test "trust_score out of range" do
    profile = profiles(:alice_profile)
    profile.trust_score = 150
    assert_not profile.valid?

    profile.trust_score = -1
    assert_not profile.valid?
  end

  test "trust_score at boundaries is valid" do
    profile = profiles(:alice_profile)
    profile.trust_score = 0
    assert profile.valid?
    profile.trust_score = 100
    assert profile.valid?
  end
end
