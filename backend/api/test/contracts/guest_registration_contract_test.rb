# frozen_string_literal: true

require "test_helper"

class GuestRegistrationContractTest < ActiveSupport::TestCase
  def contract
    GuestRegistrationContract.new
  end

  # --- happy path ---

  test "valid email-only params returns success" do
    result = contract.call({ auth: { email: "user@example.com" } })
    assert result.success?
  end

  test "valid phone-only params returns success" do
    result = contract.call({ auth: { phone: "+79991234567" } })
    assert result.success?
  end

  test "valid email + password returns success" do
    result = contract.call({ auth: { email: "user@example.com", password: "secret123" } })
    assert result.success?
  end

  # --- email_or_phone rule ---

  test "missing both email and phone returns failure" do
    result = contract.call({ auth: {} })
    assert result.failure?
    assert_includes result.errors.to_h[:auth],
      I18n.t("contracts.errors.guest_registration.auth.email_or_phone")
  end

  test "nil email and nil phone returns failure" do
    result = contract.call({ auth: { email: nil, phone: nil } })
    assert result.failure?
  end

  # --- email format rule ---

  test "invalid email format returns failure" do
    result = contract.call({ auth: { email: "not-an-email" } })
    assert result.failure?
    assert_includes result.errors.to_h.dig(:auth, :email),
      I18n.t("contracts.errors.guest_registration.email.format")
  end

  test "email with no domain returns failure" do
    result = contract.call({ auth: { email: "user@" } })
    assert result.failure?
  end

  # --- password rule ---

  test "password shorter than 8 chars returns failure" do
    result = contract.call({ auth: { email: "user@example.com", password: "short" } })
    assert result.failure?
    assert_includes result.errors.to_h.dig(:auth, :password),
      I18n.t("contracts.errors.guest_registration.password.min_size")
  end

  test "password exactly 8 chars returns success" do
    result = contract.call({ auth: { email: "user@example.com", password: "exactly8" } })
    assert result.success?
  end

  test "nil password is allowed (password-less flow)" do
    result = contract.call({ auth: { email: "user@example.com", password: nil } })
    assert result.success?
  end
end
