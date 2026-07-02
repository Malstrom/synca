# frozen_string_literal: true

require "test_helper"

class JoinSparkSessionContractTest < ActiveSupport::TestCase
  test "valid when session_code is present" do
    result = JoinSparkSessionContract.new.call({ spark_session: { session_code: "123456" } })
    assert result.success?, result.errors.to_h.inspect
  end

  test "valid when qr_token is present" do
    result = JoinSparkSessionContract.new.call({ spark_session: { qr_token: "abc123" } })
    assert result.success?, result.errors.to_h.inspect
  end

  test "invalid when neither session_code nor qr_token is provided" do
    result = JoinSparkSessionContract.new.call({ spark_session: { } })
    assert result.failure?
  end
end
