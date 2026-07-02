# frozen_string_literal: true

require "test_helper"

class SubmitSparkAnswersContractTest < ActiveSupport::TestCase
  test "valid when answers array is present" do
    result = SubmitSparkAnswersContract.new.call({ spark_session: { answers: [ 1, 2, 3 ] } })
    assert result.success?, result.errors.to_h.inspect
  end

  test "invalid when answers key is missing" do
    result = SubmitSparkAnswersContract.new.call({ spark_session: { } })
    assert result.failure?
  end
end
