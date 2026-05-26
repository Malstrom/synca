# frozen_string_literal: true

require "test_helper"

class SparkSessionTest < ActiveSupport::TestCase
  test "valid spark session" do
    assert spark_sessions(:alice_spark).valid?
  end

  test "generates session_code and qr_token on create" do
    session = SparkSession.new(initiator: users(:bob))
    session.valid?
    assert_not_nil session.session_code
    assert_equal 6, session.session_code.length
    assert_not_nil session.qr_token
  end

  test "session_code must be unique" do
    session = SparkSession.new(
      initiator:    users(:bob),
      session_code: spark_sessions(:alice_spark).session_code,
      qr_token:     SecureRandom.uuid,
      status:       :pending
    )
    assert_not session.valid?
    assert session.errors[:session_code].any?
  end

  test "both_answered? returns true when both answers present" do
    s = spark_sessions(:alice_spark)
    s.initiator_answers = [ "a1" ]
    s.partner_answers   = [ "b2" ]
    assert s.both_answered?
  end

  test "both_answered? returns false when only one side answered" do
    s = spark_sessions(:alice_spark)
    s.initiator_answers = [ "a1" ]
    s.partner_answers   = nil
    assert_not s.both_answered?
  end

  test "stale scope returns old pending sessions" do
    old = spark_sessions(:pending_spark)
    old.update_columns(created_at: 15.minutes.ago)
    assert_includes SparkSession.stale, old
  end

  test "one active session per initiator on create" do
    # bob already has pending_spark in fixtures
    duplicate = SparkSession.new(initiator: users(:bob), status: :pending)
    duplicate.valid?
    assert duplicate.errors[:base].any?
  end

  test "expired? returns true for old pending session" do
    session = spark_sessions(:alice_spark)
    session.update!(created_at: 11.minutes.ago, status: :pending)
    assert session.expired?
  end
end
