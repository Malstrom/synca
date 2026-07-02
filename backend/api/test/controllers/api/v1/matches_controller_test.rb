# frozen_string_literal: true

require "test_helper"

class Api::V1::MatchesControllerTest < ApiTestCase
  setup do
    @alice = users(:alice)
    @bob   = users(:bob)
    @alice_headers = auth_headers(@alice)
  end

  # --- POST /api/v1/matches/simulate ---

  test "simulate returns compatibility_score and dimensions for two users with health data" do
    post_json "/api/v1/matches/simulate",
      params: { user_id: @alice.id, other_user_id: @bob.id },
      headers: @alice_headers

    assert_response :ok
    assert json[:compatibility_score].present?
    assert json[:dimensions].present?
    assert json[:dimensions].key?(:sleep_rhythm)
    assert json[:dimensions].key?(:energy_overlap)
    assert json[:dimensions].key?(:lifestyle)
  end

  test "simulate returns 422 when user_id is missing" do
    post_json "/api/v1/matches/simulate",
      params: { other_user_id: @bob.id },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "missing_params", json.dig(:error, :code)
  end

  test "simulate returns 422 when other_user_id is missing" do
    post_json "/api/v1/matches/simulate",
      params: { user_id: @alice.id },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "missing_params", json.dig(:error, :code)
  end

  test "simulate returns 404 when user does not exist" do
    post_json "/api/v1/matches/simulate",
      params: { user_id: 0, other_user_id: @bob.id },
      headers: @alice_headers

    assert_response :not_found
    assert_equal "not_found", json.dig(:error, :code)
  end

  test "simulate returns 422 when users are the same" do
    post_json "/api/v1/matches/simulate",
      params: { user_id: @alice.id, other_user_id: @alice.id },
      headers: @alice_headers

    assert_response :unprocessable_entity
    assert_equal "missing_params", json.dig(:error, :code)
  end

  test "simulate returns score of 0 dimensions when health data is missing" do
    user_without_health = users(:dave)

    post_json "/api/v1/matches/simulate",
      params: { user_id: @alice.id, other_user_id: user_without_health.id },
      headers: @alice_headers

    assert_response :ok
    assert json[:compatibility_score].present?
  end

  test "simulate requires authentication" do
    post_json "/api/v1/matches/simulate",
      params: { user_id: @alice.id, other_user_id: @bob.id }

    assert_response :unauthorized
  end

  # --- GET /api/v1/matches ---

  test "index returns matches for current user" do
    get "/api/v1/matches", headers: @alice_headers

    assert_response :ok
    assert_kind_of Array, json[:matches]
    assert json[:matches].length >= 1
  end

  test "index returns participant profiles in each match" do
    get "/api/v1/matches", headers: @alice_headers

    match = json[:matches].first
    assert match[:compatibility_score].present?
    assert match[:status].present?
    assert_kind_of Array, match[:participants]
    assert match[:participants].first[:profile].present?
  end

  test "index returns empty array when user has no matches" do
    get "/api/v1/matches", headers: auth_headers(users(:charlie))

    assert_response :ok
    assert_equal [], json[:matches]
  end

  test "index requires authentication" do
    get "/api/v1/matches"

    assert_response :unauthorized
  end
end
