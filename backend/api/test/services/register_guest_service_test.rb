# frozen_string_literal: true

require "test_helper"

class RegisterGuestServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  def call(email: "guest_#{SecureRandom.hex(4)}@example.com")
    RegisterGuestService.call(params: { auth: { email: email } })
  end

  # --- Success ---

  test "returns Success(guest user) with a valid email" do
    result = call
    assert_pattern { result => Success(User) }
    assert_equal "guest", result.value!.account_type
  end

  test "creates a new guest user" do
    assert_difference "User.count", 1 do
      call
    end
  end

  test "downcases email" do
    result = call(email: "GUEST@EXAMPLE.COM")
    assert_pattern { result => Success }
    assert_equal "guest@example.com", result.value!.email
  end

  test "reuses existing guest user with same email" do
    email = "returning@example.com"
    call(email: email)
    assert_no_difference "User.count" do
      result = call(email: email)
      assert_pattern { result => Success }
      pass
    end
  end

  # --- email_already_active ---

  test "returns Failure[:email_already_active] when email belongs to active user" do
    result = call(email: users(:alice).email)
    assert_pattern { result => Failure[:email_already_active, _] }
    pass
  end

  test "Failure[:email_already_active] carries the i18n message" do
    result = call(email: users(:alice).email)
    assert_equal I18n.t("errors.auth.email_already_active"), result.failure.last
  end

  # --- validation_failed ---

  test "returns Failure[:validation_failed] when email is missing" do
    result = RegisterGuestService.call(params: { auth: {} })
    assert_pattern { result => Failure[:validation_failed, _] }
    pass
  end
end
