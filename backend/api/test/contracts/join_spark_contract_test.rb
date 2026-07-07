# frozen_string_literal: true

require "test_helper"

class JoinSparkContractTest < ActiveSupport::TestCase
  test "valid when session_code is present" do
    result = JoinSparkContract.new.call({ spark: { session_code: "123456" } })
    assert result.success?, result.errors.to_h.inspect
  end

  test "valid when qr_token is present" do
    result = JoinSparkContract.new.call({ spark: { qr_token: "abc123" } })
    assert result.success?, result.errors.to_h.inspect
  end

  test "invalid when neither session_code nor qr_token is provided" do
    result = JoinSparkContract.new.call({ spark: {} })
    assert result.failure?
  end
end
