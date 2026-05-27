# frozen_string_literal: true

require "test_helper"

class Api::V1::SparkSessionsControllerTest < ApiTestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @alice_headers = auth_headers(@alice)
    @bob_headers   = auth_headers(@bob)
  end

  # --- POST /spark_sessions (create) ---

  test "create returns 201 with session_code, qr_token and pending status" do
    post_json "/api/v1/spark_sessions",
      params: {},
      headers: @alice_headers

    assert_response :created
    assert json[:session_code].present?
    assert json[:qr_token].present?
    assert_equal "pending", json[:status]
  end

  test "create with optional location stores lat and lng" do
    post_json "/api/v1/spark_sessions",
      params: { spark_session: { lat: 55.7558, lng: 37.6176 } },
      headers: @alice_headers

    assert_response :created
    assert_in_delta 55.7558, json[:location_lat], 0.0001
    assert_in_delta 37.6176, json[:location_lng], 0.0001
  end

  test "create without token returns 401" do
    post_json "/api/v1/spark_sessions", params: {}

    assert_response :unauthorized
  end

  test "create returns 422 when user already has an active session" do
    post_json "/api/v1/spark_sessions",
      params: {},
      headers: @alice_headers
    assert_response :created

    post_json "/api/v1/spark_sessions",
      params: {},
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "validation_failed", json.dig(:error, :code)
  end

  # --- POST /spark_sessions/:id/join ---

  test "join sets partner, transitions to active and returns 200" do
    session = create_pending_session_for(@alice)

    post_json "/api/v1/spark_sessions/#{session.id}/join",
      params: { spark_session: { session_code: session.session_code } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
    assert json[:started_at].present?
  end

  test "join with qr_token works" do
    session = create_pending_session_for(@alice)

    post_json "/api/v1/spark_sessions/#{session.id}/join",
      params: { spark_session: { qr_token: session.qr_token } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
  end

  test "join with wrong session_code returns 422" do
    session = create_pending_session_for(@alice)

    post_json "/api/v1/spark_sessions/#{session.id}/join",
      params: { spark_session: { session_code: "000000" } },
      headers: @bob_headers

    assert_response :unprocessable_entity
    assert_equal "invalid_code", json.dig(:error, :code)
  end

  test "join own session returns 422" do
    session = create_pending_session_for(@alice)

    post_json "/api/v1/spark_sessions/#{session.id}/join",
      params: { spark_session: { session_code: session.session_code } },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "cannot_join_own_session", json.dig(:error, :code)
  end

  test "join an already active session returns 422" do
    session = create_pending_session_for(@alice)
    session.update!(partner_id: @bob.id, status: :active, started_at: Time.current)

    third_user = users(:charlie)
    post_json "/api/v1/spark_sessions/#{session.id}/join",
      params: { spark_session: { session_code: session.session_code } },
      headers: auth_headers(third_user)

    assert_response :unprocessable_entity
    assert_equal "session_not_joinable", json.dig(:error, :code)
  end

  # --- POST /spark_sessions/:id/submit_answers ---

  test "submit_answers stores initiator answers and returns 200" do
    session = create_active_session_for(@alice, @bob)

    post_json "/api/v1/spark_sessions/#{session.id}/submit_answers",
      params: { spark_session: { answers: [ 1, 2, 3 ] } },
      headers: @alice_headers

    assert_response :ok
    assert_equal [ 1, 2, 3 ], session.reload.initiator_answers
  end

  test "submit_answers stores partner answers and returns 200" do
    session = create_active_session_for(@alice, @bob)

    post_json "/api/v1/spark_sessions/#{session.id}/submit_answers",
      params: { spark_session: { answers: [ 4, 5, 6 ] } },
      headers: @bob_headers

    assert_response :ok
    assert_equal [ 4, 5, 6 ], session.reload.partner_answers
  end

  test "submit_answers enqueues SparkScoringJob when both users have answered" do
    session = create_active_session_for(@alice, @bob)
    session.update!(initiator_answers: [ 1, 2, 3 ])

    assert_enqueued_with(job: SparkScoringJob, args: [ session.id ]) do
      post_json "/api/v1/spark_sessions/#{session.id}/submit_answers",
        params: { spark_session: { answers: [ 4, 5, 6 ] } },
        headers: @bob_headers
    end
  end

  test "submit_answers does not enqueue SparkScoringJob when only one side answered" do
    session = create_active_session_for(@alice, @bob)

    assert_no_enqueued_jobs(only: SparkScoringJob) do
      post_json "/api/v1/spark_sessions/#{session.id}/submit_answers",
        params: { spark_session: { answers: [ 1, 2, 3 ] } },
        headers: @alice_headers
    end
  end

  test "submit_answers on non-active session returns 422" do
    session = create_pending_session_for(@alice)

    post_json "/api/v1/spark_sessions/#{session.id}/submit_answers",
      params: { spark_session: { answers: [ 1, 2, 3 ] } },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "session_not_active", json.dig(:error, :code)
  end

  # --- GET /spark_sessions/:id/result ---

  test "result returns compatibility score and dimensions when session is completed" do
    session = create_completed_session_for(@alice, @bob)

    get "/api/v1/spark_sessions/#{session.id}/result", headers: @alice_headers

    assert_response :ok
    assert json[:compatibility_score].present?
    assert json[:dimensions].present?
    assert json[:rewards].present?
  end

  test "result returns 422 when session is not yet completed" do
    session = create_active_session_for(@alice, @bob)

    get "/api/v1/spark_sessions/#{session.id}/result", headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "session_not_completed", json.dig(:error, :code)
  end

  test "result returns 403 when user is not a participant" do
    session = create_completed_session_for(@alice, @bob)

    get "/api/v1/spark_sessions/#{session.id}/result",
      headers: auth_headers(users(:charlie))

    assert_response :forbidden
  end

  # --- GET /spark_rewards ---

  test "spark_rewards returns list of rewards for current user" do
    get "/api/v1/spark_rewards", headers: @alice_headers

    assert_response :ok
    assert_kind_of Array, json[:rewards]
  end

  test "spark_rewards without token returns 401" do
    get "/api/v1/spark_rewards"

    assert_response :unauthorized
  end

  private

    def create_pending_session_for(user)
      SparkSession.create!(
        initiator: user,
        status: :pending
      )
    end

    def create_active_session_for(initiator, partner)
      SparkSession.create!(
        initiator: initiator,
        partner:   partner,
        status:    :active,
        started_at: Time.current
      )
    end

    def create_completed_session_for(initiator, partner)
      session = SparkSession.create!(
        initiator:            initiator,
        partner:              partner,
        status:               :completed,
        started_at:           1.hour.ago,
        completed_at:         Time.current,
        initiator_answers:    [ 1, 2, 3 ],
        partner_answers:      [ 1, 2, 3 ],
        compatibility_score:  82.5
      )
      SparkReward.create!(
        user:          initiator,
        spark_session: session,
        reward_type:   :premium_week,
        status:        :pending,
        valid_until:   7.days.from_now
      )
      SparkReward.create!(
        user:          partner,
        spark_session: session,
        reward_type:   :premium_week,
        status:        :pending,
        valid_until:   7.days.from_now
      )
      session
    end
end
