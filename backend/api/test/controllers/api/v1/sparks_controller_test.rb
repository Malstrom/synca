# frozen_string_literal: true

require "test_helper"

class Api::V1::SparksControllerTest < ApiTestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @alice_headers = auth_headers(@alice)
    @bob_headers   = auth_headers(@bob)
  end

  # --- POST /sparks (create) ---

  test "create returns 201 with session_code, qr_token and pending status" do
    post_json "/api/v1/sparks",
      params: {},
      headers: @alice_headers

    assert_response :created
    assert json[:session_code].present?
    assert json[:qr_token].present?
    assert_equal "pending", json[:status]
  end

  test "create with optional location stores lat and lng" do
    post_json "/api/v1/sparks",
      params: { spark: { lat: 55.7558, lng: 37.6176 } },
      headers: @alice_headers

    assert_response :created
    assert_in_delta 55.7558, json[:location_lat], 0.0001
    assert_in_delta 37.6176, json[:location_lng], 0.0001
  end

  test "create without token returns 401" do
    post_json "/api/v1/sparks", params: {}

    assert_response :unauthorized
  end

  test "create allows multiple concurrent sparks for the same user" do
    post_json "/api/v1/sparks",
      params: {},
      headers: @alice_headers
    assert_response :created

    post_json "/api/v1/sparks",
      params: {},
      headers: @alice_headers

    assert_response :created
  end

  # --- POST /sparks/:id/join ---

  test "join sets partner, transitions to active and returns 200" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/#{spark.id}/join",
      params: { spark: { session_code: spark.session_code } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
    assert json[:started_at].present?
  end

  test "join with qr_token works" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/#{spark.id}/join",
      params: { spark: { qr_token: spark.qr_token } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
  end

  test "join with wrong session_code returns 422" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/#{spark.id}/join",
      params: { spark: { session_code: "000000" } },
      headers: @bob_headers

    assert_response :unprocessable_entity
    assert_equal "invalid_code", json.dig(:error, :code)
  end

  test "join own spark returns 422" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/#{spark.id}/join",
      params: { spark: { session_code: spark.session_code } },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "cannot_join_own_spark", json.dig(:error, :code)
  end

  test "join an already active spark returns 422" do
    spark = sparks(:active_no_answers)

    post_json "/api/v1/sparks/#{spark.id}/join",
      params: { spark: { session_code: spark.session_code } },
      headers: auth_headers(users(:charlie))

    assert_response :unprocessable_entity
    assert_equal "spark_not_joinable", json.dig(:error, :code)
  end

  # --- POST /sparks/join (no id — the real QR-scan/manual-code UX) ---

  test "join by session_code (no id) sets partner, transitions to active and returns 200" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/join",
      params: { spark: { session_code: spark.session_code } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
    assert_equal spark.id, json[:id]
  end

  test "join by qr_token (no id) sets partner, transitions to active and returns 200" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/join",
      params: { spark: { qr_token: spark.qr_token } },
      headers: @bob_headers

    assert_response :ok
    assert_equal "active", json[:status]
  end

  test "join by code with an unknown session_code returns 404" do
    post_json "/api/v1/sparks/join",
      params: { spark: { session_code: "ZZZZZZ" } },
      headers: @bob_headers

    assert_response :not_found
  end

  test "join by code with an unknown qr_token returns 404" do
    post_json "/api/v1/sparks/join",
      params: { spark: { qr_token: "00000000-0000-0000-0000-000000000000" } },
      headers: @bob_headers

    assert_response :not_found
  end

  test "join by code with neither session_code nor qr_token returns 404" do
    post_json "/api/v1/sparks/join",
      params: { spark: {} },
      headers: @bob_headers

    assert_response :not_found
  end

  test "join by code own spark returns 422" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/join",
      params: { spark: { session_code: spark.session_code } },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "cannot_join_own_spark", json.dig(:error, :code)
  end

  test "join by code without a token returns 401" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/join",
      params: { spark: { session_code: spark.session_code } }

    assert_response :unauthorized
  end

  # --- POST /sparks/:id/submit_answers ---

  test "submit_answers stores initiator answers and returns 200" do
    spark = sparks(:active_no_answers)

    post_json "/api/v1/sparks/#{spark.id}/submit_answers",
      params: { spark: { answers: [ 1, 2, 3 ] } },
      headers: @alice_headers

    assert_response :ok
    assert_equal [ 1, 2, 3 ], spark.reload.initiator_answers
  end

  test "submit_answers stores partner answers and returns 200" do
    spark = sparks(:active_no_answers)

    post_json "/api/v1/sparks/#{spark.id}/submit_answers",
      params: { spark: { answers: [ 4, 5, 6 ] } },
      headers: @bob_headers

    assert_response :ok
    assert_equal [ 4, 5, 6 ], spark.reload.partner_answers
  end

  test "submit_answers enqueues SparkScoringJob when both users have answered" do
    spark = sparks(:active_awaiting_partner_answers)

    assert_enqueued_with(job: SparkScoringJob, args: [ spark.id ]) do
      post_json "/api/v1/sparks/#{spark.id}/submit_answers",
        params: { spark: { answers: [ 4, 5, 6 ] } },
        headers: @bob_headers
    end
  end

  test "submit_answers does not enqueue SparkScoringJob when only one side answered" do
    spark = sparks(:active_no_answers)

    assert_no_enqueued_jobs(only: SparkScoringJob) do
      post_json "/api/v1/sparks/#{spark.id}/submit_answers",
        params: { spark: { answers: [ 1, 2, 3 ] } },
        headers: @alice_headers
    end
  end

  test "submit_answers on non-active spark returns 422" do
    spark = sparks(:alice_pending_spark)

    post_json "/api/v1/sparks/#{spark.id}/submit_answers",
      params: { spark: { answers: [ 1, 2, 3 ] } },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "session_not_active", json.dig(:error, :code)
  end

  # --- GET /sparks/:id/result ---

  test "result returns compatibility score and dimensions when spark is completed" do
    spark = sparks(:alice_spark)

    get "/api/v1/sparks/#{spark.id}/result", headers: @alice_headers

    assert_response :ok
    assert json[:compatibility_score].present?
    assert json[:dimensions].present?
    assert json[:rewards].present?
  end

  test "result returns 422 when spark is not yet completed" do
    spark = sparks(:active_no_answers)

    get "/api/v1/sparks/#{spark.id}/result", headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "spark_not_completed", json.dig(:error, :code)
  end

  test "result returns 403 when user is not a participant" do
    spark = sparks(:alice_spark)

    get "/api/v1/sparks/#{spark.id}/result",
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
end
