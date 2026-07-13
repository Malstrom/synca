# frozen_string_literal: true

require "test_helper"

class ActivateUserServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  # --- success cases ---

  test "activates a user successfully" do
    assert_pattern do
      ActivateUserService.call(user: @user) => Success(user)
    end

    assert user.reload.account_type, "active"
  end

  # --- failure cases ---

  test "fails when user is already active" do
    @user.update!(account_type: "active")

    assert_pattern do
      ActivateUserService.call(user: @user) => Failure([:already_active, _])
    end
  end

  test "fails when user is not found" do
    assert_pattern do
      ActivateUserService.call(user: User.new(id: 9999)) => Failure([:not_found, _])
    end
  end

  # --- interface ---

  test "exposes class-level call interface" do
    assert_respond_to ActivateUserService, :call
  end

  test "exposes class-level activate interface" do
    assert_respond_to ActivateUserService, :activate
  end

  test "call and activate interfaces are equivalent" do
    result_call = ActivateUserService.call(user: @user)
    result_activate = ActivateUserService.activate(user: @user)

    assert_equal result_call, result_activate
  end
end