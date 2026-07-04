# frozen_string_literal: true

require "test_helper"

# Profile model is intentionally thin: enum + association only.
# Validation rules live in ProfileContract — see test/contracts/profile_contract_test.rb
class ProfileTest < ActiveSupport::TestCase
  test "valid profile" do
    assert profiles(:alice_profile).valid?
  end

  test "gender enum maps correctly" do
    profile = profiles(:alice_profile)
    assert_includes Profile.genders.keys, profile.gender
  end

  test "trust_score at boundaries is valid" do
    profile = profiles(:alice_profile)
    profile.trust_score = 0
    assert profile.valid?
    profile.trust_score = 100
    assert profile.valid?
  end

  test "intentional failure to smoke-test CI report" do
    assert false, "questo test fallisce di proposito — smoke test CI report"
  end
end
