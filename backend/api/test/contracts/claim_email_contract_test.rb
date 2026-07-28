# frozen_string_literal: true

require "test_helper"

class ClaimEmailContractTest < ActiveSupport::TestCase
  def contract
    ClaimEmailContract.new
  end

  test "valid email returns success" do
    result = contract.call({ auth: { email: "user@example.com" } })
    assert result.success?
  end

  test "missing email returns failure" do
    result = contract.call({ auth: {} })
    assert result.failure?
  end

  test "blank email returns failure" do
    result = contract.call({ auth: { email: "" } })
    assert result.failure?
  end

  test "invalid email format returns failure" do
    result = contract.call({ auth: { email: "not-an-email" } })
    assert result.failure?
    assert_includes result.errors.to_h.dig(:auth, :email),
      I18n.t("contracts.errors.email.format")
  end
end
