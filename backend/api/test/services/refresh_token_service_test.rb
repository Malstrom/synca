# frozen_string_literal: true

require "test_helper"

class RefreshTokenServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @user          = users(:alice)
    @refresh_token = JwtService.refresh_token(@user)
    @access_token  = JwtService.access_token(@user)
  end

  def call(token)
    RefreshTokenService.call(params: { auth: { refresh_token: token } })
  end

  # --- Success ---

  test "returns Success(access_token) with a valid refresh token" do
    result = call(@refresh_token)
    assert_pattern { result => Success(String) }
    pass
  end

  test "issued access token is decodable and belongs to the user" do
    result = call(@refresh_token)
    payload = JwtService.decode(result.value!)
    assert_equal @user.id, payload["sub"]
    assert_equal "access",  payload["type"]
  end

  # --- invalid_token ---

  test "returns Failure[:invalid_token] for a garbage token" do
    result = call("not-a-token")
    assert_pattern { result => Failure[:invalid_token, _] }
    pass
  end

  test "returns Failure[:invalid_token] when token type is access (not refresh)" do
    result = call(@access_token)
    assert_pattern { result => Failure[:invalid_token, _] }
    pass
  end

  test "Failure[:invalid_token] carries the i18n message" do
    result = call("garbage")
    assert_equal I18n.t("errors.auth.invalid_token"), result.failure.last
  end

  # --- user_not_found ---

  test "returns Failure[:user_not_found] when user no longer exists" do
    token = @refresh_token
    @user.destroy!
    result = call(token)
    assert_pattern { result => Failure[:user_not_found, _] }
    pass
  end
end
