# frozen_string_literal: true

require "test_helper"

class ActivationContractTest < ActiveSupport::TestCase
  def contract
    ActivationContract.new
  end

  test "valid display_name and password returns success" do
    result = contract.call({ profile: { display_name: "Jane" }, auth: { password: "password123" } })
    assert result.success?
  end

  test "missing display_name returns failure" do
    result = contract.call({ profile: {}, auth: { password: "password123" } })
    assert result.failure?
  end

  test "blank display_name returns failure" do
    result = contract.call({ profile: { display_name: "" }, auth: { password: "password123" } })
    assert result.failure?
  end

  test "missing password returns failure" do
    result = contract.call({ profile: { display_name: "Jane" }, auth: {} })
    assert result.failure?
  end

  test "password shorter than minimum length returns failure" do
    result = contract.call({ profile: { display_name: "Jane" }, auth: { password: "short" } })
    assert result.failure?
    assert_includes result.errors.to_h.dig(:auth, :password),
      I18n.t("contracts.errors.password.min_size")
  end
end
