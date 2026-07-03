# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with email and password" do
    user = User.new(email: "new@example.com", password: "secret123", auth_provider: :email)
    assert user.valid?
  end

  test "valid social login without email" do
    user = User.new(auth_provider: :apple, provider_uid: "uid_abc", phone: "+79001111111")
    assert user.valid?
  end

  test "invalid without email or phone for email auth" do
    user = User.new(auth_provider: :email, password: "secret123")
    assert_not user.valid?
    assert_includes user.errors[:base], "email or phone is required for email auth"
  end

  test "invalid with duplicate email" do
    user = User.new(email: users(:alice).email, password: "secret123", auth_provider: :email)
    assert_not user.valid?
    assert user.errors[:email].any?
  end

  test "invalid with malformed email" do
    user = User.new(email: "not-an-email", password: "secret123", auth_provider: :email)
    assert_not user.valid?
  end

  test "has associations" do
    alice = users(:alice)
    assert_respond_to alice, :profile
    assert_respond_to alice, :health_summary
    assert_respond_to alice, :preference_profile
    assert_respond_to alice, :matches
    assert_respond_to alice, :spark_rewards
  end

  test "account_type enum has correct integer mapping for guest and active" do
    assert_equal 0, User.account_types[:guest]
    assert_equal 1, User.account_types[:active]
  end

  test "alice fixture has account_type active" do
    assert_equal "active", users(:alice).account_type
  end
end
