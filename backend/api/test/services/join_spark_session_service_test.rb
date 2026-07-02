# frozen_string_literal: true

require "test_helper"

class JoinSparkSessionServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
  end

  test "joins pending session with valid session_code" do
    session = SparkSession.create!(initiator: @alice, status: :pending)

    result = JoinSparkSessionService.call(
      current_user: @bob,
      spark_session: session,
      attrs: { session_code: session.session_code }
    )

    assert result.success?, "expected Success, got #{result.inspect}"

    joined = result.value!
    assert_equal @bob.id, joined.partner_id
    assert_equal "active", joined.status
    assert joined.started_at.present?
  end

  test "returns cannot_join_own_session when initiator tries to join" do
    session = SparkSession.create!(initiator: @alice, status: :pending)

    result = JoinSparkSessionService.call(
      current_user: @alice,
      spark_session: session,
      attrs: { session_code: session.session_code }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :cannot_join_own_session, code
  end

  test "returns session_not_joinable when session is not pending" do
    session = SparkSession.create!(initiator: @alice, status: :active)

    result = JoinSparkSessionService.call(
      current_user: @bob,
      spark_session: session,
      attrs: { session_code: session.session_code }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :session_not_joinable, code
  end

  test "returns invalid_code when code/token do not match" do
    session = SparkSession.create!(initiator: @alice, status: :pending)

    result = JoinSparkSessionService.call(
      current_user: @bob,
      spark_session: session,
      attrs: { session_code: "000000" }
    )

    assert result.failure?, "expected Failure, got #{result.inspect}"
    code, _message = result.failure
    assert_equal :invalid_code, code
  end
end
