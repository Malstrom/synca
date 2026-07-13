# frozen_string_literal: true

require "test_helper"

class RegisterGuestServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  def call(overrides = {})
    defaults = { auth: { device_id: "device-abc" } }
    RegisterGuestService.call(params: deep_merge(defaults, overrides))
  end

  def deep_merge(base, overrides)
    base.merge(overrides) { |_, old, new_val| old.is_a?(Hash) ? old.merge(new_val) : new_val }
  end

  # --- Success (no email) ---

  test "returns Success(user) with only device_id" do
    result = call
    assert_pattern { result => Success(User) }
    assert_equal "guest", result.value!.account_type
  end

  test "creates a new guest user each time without email" do
    assert_difference "User.count", 1 do
      call
    end
  end

  # --- Success (with email, new guest) ---

  test "returns Success when email does not exist yet" do
    result = call(auth: { email: "newguest@example.com", device_id: "d1" })
    assert_pattern { result => Success(User) }
    assert_equal "newguest@example.com", result.value!.email
  end

  test "reuses existing guest user with same email" do
    call(auth: { email: "returning@example.com", device_id: "d1" })
    assert_no_difference "User.count" do
      result = call(auth: { email: "returning@example.com", device_id: "d2" })
      assert_pattern { result => Success }
      pass
    end
  end

  test "downcases email" do
    result = call(auth: { email: "GUEST@EXAMPLE.COM", device_id: "d1" })
    assert_pattern { result => Success }
    assert_equal "guest@example.com", result.value!.email
  end

  # --- email_already_active ---

  test "returns Failure[:email_already_active] when email belongs to active user" do
    result = call(auth: { email: users(:alice).email, device_id: "d1" })
    assert_pattern { result => Failure[:email_already_active, _] }
    pass
  end

  test "Failure[:email_already_active] carries the i18n message" do
    result = call(auth: { email: users(:alice).email, device_id: "d1" })
    assert_equal I18n.t("errors.auth.email_already_active"), result.failure.last
  end

  # --- validation_failed ---

  test "returns Failure[:validation_failed] when device_id is missing" do
    result = RegisterGuestService.call(params: { auth: {} })
    assert_pattern { result => Failure[:validation_failed, _] }
    pass
  end
end
