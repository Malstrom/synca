# frozen_string_literal: true

require "test_helper"

class RegisterUserServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  # --- helpers ---

  def call(overrides = {})
    defaults = { auth: { email: "new@example.com", password: "password123", auth_provider: "email" } }
    RegisterUserService.call(params: deep_merge(defaults, overrides))
  end

  def deep_merge(base, overrides)
    base.merge(overrides) { |_, old, new_val| old.is_a?(Hash) ? old.merge(new_val) : new_val }
  end

  # --- Success ---

  test "returns Success(user) on valid params" do
    result = call
    assert_pattern { result => Success(User) }
    assert_equal "new@example.com", result.value!.email
  end

  test "downcases email before saving" do
    result = call(auth: { email: "NEW@EXAMPLE.COM" })
    assert_pattern { result => Success }
    assert_equal "new@example.com", result.value!.email
  end

  test "works with oauth provider (no email required)" do
    result = RegisterUserService.call(params: {
      auth: { auth_provider: "apple", provider_uid: "uid-123" }
    })
    assert_pattern { result => Success(User) }
    pass
  end

  # --- email_taken ---

  test "returns Failure[:email_taken] when email already exists" do
    call  # first registration
    result = call  # duplicate
    assert_pattern { result => Failure[:email_taken, _] }
    pass
  end

  test "Failure[:email_taken] carries the i18n message" do
    call
    result = call
    assert_equal I18n.t("errors.auth.email_taken"), result.failure.last
  end

  # --- validation_failed ---

  test "returns Failure[:validation_failed] when email format is invalid" do
    result = call(auth: { email: "not-an-email" })
    assert_pattern { result => Failure[:validation_failed, _] }
    pass
  end

  test "returns Failure[:validation_failed] when password is too short" do
    result = call(auth: { password: "short" })
    assert_pattern { result => Failure[:validation_failed, _] }
    pass
  end

  test "returns Failure[:validation_failed] when auth_provider is missing" do
    result = RegisterUserService.call(params: { auth: { email: "x@x.com", password: "password123" } })
    assert_pattern { result => Failure[:validation_failed, _] }
    pass
  end
end
