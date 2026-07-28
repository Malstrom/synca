# frozen_string_literal: true

require "test_helper"

class ActivationContractTest < ActiveSupport::TestCase
  def contract
    ActivationContract.new
  end

  test "valid display_name returns success" do
    result = contract.call({ profile: { display_name: "Jane" } })
    assert result.success?
  end

  test "missing display_name returns failure" do
    result = contract.call({ profile: {} })
    assert result.failure?
  end

  test "blank display_name returns failure" do
    result = contract.call({ profile: { display_name: "" } })
    assert result.failure?
  end
end
