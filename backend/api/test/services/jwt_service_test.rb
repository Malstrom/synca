require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  # --- access_token ---

  test "access_token returns a non-nil string" do
    token = JwtService.access_token(@user)
    assert_kind_of String, token
    assert token.present?
  end

  test "access_token payload has correct sub and type" do
    token = JwtService.access_token(@user)
    payload = JwtService.decode(token)
    assert_equal @user.id, payload["sub"]
    assert_equal "access",  payload["type"]
  end

  test "access_token expires in ~15 minutes" do
    token = JwtService.access_token(@user)
    payload = JwtService.decode(token)
    remaining = payload["exp"] - Time.now.to_i
    assert_operator remaining, :>, 0
    assert_operator remaining, :<=, 16.minutes.to_i
  end

  # --- refresh_token ---

  test "refresh_token returns a non-nil string" do
    token = JwtService.refresh_token(@user)
    assert_kind_of String, token
    assert token.present?
  end

  test "refresh_token payload has correct sub and type" do
    token = JwtService.refresh_token(@user)
    payload = JwtService.decode(token)
    assert_equal @user.id, payload["sub"]
    assert_equal "refresh", payload["type"]
  end

  test "refresh_token expires in ~30 days" do
    token = JwtService.refresh_token(@user)
    payload = JwtService.decode(token)
    remaining = payload["exp"] - Time.now.to_i
    assert_operator remaining, :>, 29.days.to_i
    assert_operator remaining, :<=, 31.days.to_i
  end

  # --- decode ---

  test "decode returns nil for a corrupted token" do
    assert_nil JwtService.decode("not.a.valid.token")
  end

  test "decode returns nil for a tampered token" do
    token = JwtService.access_token(@user)
    tampered = token[0..-5] + "XXXX"
    assert_nil JwtService.decode(tampered)
  end

  test "decode returns nil for an expired token" do
    # encode a token already expired
    payload = { sub: @user.id, type: "access", exp: 1.minute.ago.to_i }
    secret = ENV["SECRET_KEY_BASE"].presence || Rails.application.credentials.secret_key_base
    token = JWT.encode(payload, secret, "HS256")
    assert_nil JwtService.decode(token)
  end

  # --- access vs refresh are not interchangeable (controller-level guard) ---

  test "access_token and refresh_token differ" do
    access  = JwtService.access_token(@user)
    refresh = JwtService.refresh_token(@user)
    refute_equal access, refresh
  end
end
