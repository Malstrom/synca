# frozen_string_literal: true

require "test_helper"

class LoginServiceTest < ActiveSupport::TestCase
  setup do
    @password = "secret123"
    @user = users(:one)
    @user.update!(password: @password)
  end

  def call(email: @user.email, pw: @password)
    LoginService.call(params: { auth: { email: email, password: pw } })
  end

  # --- Success ---

  test "returns Success(user) on valid credentials" do
    result = call
    assert result.success?
    assert_equal @user, result.value!
  end

  test "is case-insensitive on email" do
    result = call(email: @user.email.upcase)
    assert result.success?
  end

  # --- Invalid credentials ---

  test "returns Failure[:invalid_credentials] on wrong password" do
    result = call(pw: "wrongpassword")
    assert result.failure?
    assert_equal :invalid_credentials, result.failure.first
    assert_equal I18n.t("errors.auth.invalid_credentials"), result.failure.last
  end

  test "returns Failure[:invalid_credentials] when user does not exist" do
    result = call(email: "nobody@example.com")
    assert result.failure?
    assert_equal :invalid_credentials, result.failure.first
  end

  # --- Contract validation ---

  test "returns Failure[:validation_failed] when email is missing" do
    result = LoginService.call(params: { auth: { password: @password } })
    assert result.failure?
    assert_equal :validation_failed, result.failure.first
    assert_respond_to result.failure.last, :errors
  end

  test "returns Failure[:validation_failed] when password is too short" do
    result = call(pw: "short")
    assert result.failure?
    assert_equal :validation_failed, result.failure.first
    assert_respond_to result.failure.last, :errors
  end
end
