# frozen_string_literal: true

require "test_helper"

class LoginServiceTest < ActiveSupport::TestCase
  include Dry::Monads[:result]

  setup do
    @password = "secret123"
    @user = users(:alice)
    @user.update!(password: @password)
  end

  def call(email: @user.email, pw: @password)
    LoginService.call(params: { auth: { email: email, password: pw } })
  end

  # --- Success ---

  test "returns Success(user) on valid credentials" do
    assert_pattern { call => Success(@user) }
  end

  test "is case-insensitive on email" do
    assert_pattern { call(email: @user.email.upcase) => Success }
  end

  # --- Invalid credentials ---

  test "returns Failure[:invalid_credentials] on wrong password" do
    assert_pattern { call(pw: "wrongpassword") => Failure[:invalid_credentials, _] }
  end

  test "Failure[:invalid_credentials] carries the i18n message" do
    result = call(pw: "wrongpassword")
    assert_equal I18n.t("errors.auth.invalid_credentials"), result.failure.last
  end

  test "returns Failure[:invalid_credentials] when user does not exist" do
    assert_pattern { call(email: "nobody@example.com") => Failure[:invalid_credentials, _] }
  end

  # --- Contract validation ---

  test "returns Failure[:validation_failed] when email is missing" do
    result = LoginService.call(params: { auth: { password: @password } })
    assert_pattern { result => Failure[:validation_failed, _] }
    assert_respond_to result.failure.last, :errors
  end

  test "returns Failure[:validation_failed] when password is too short" do
    result = call(pw: "short")
    assert_pattern { result => Failure[:validation_failed, _] }
    assert_respond_to result.failure.last, :errors
  end
end
