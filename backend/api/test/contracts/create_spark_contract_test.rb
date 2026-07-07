# frozen_string_literal: true

require "test_helper"

class CreateSparkContractTest < ActiveSupport::TestCase
  test "empty params are valid" do
    result = CreateSparkContract.new.call({})
    assert result.success?, result.errors.to_h.inspect
  end

  test "valid lat/lng pass" do
    result = CreateSparkContract.new.call({ spark: { lat: 55.7558, lng: 37.6176 } })
    assert result.success?, result.errors.to_h.inspect
  end
end
