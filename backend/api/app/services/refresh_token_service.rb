# frozen_string_literal: true

# Validates a refresh token and issues a new access token.
#
# @example
#   case RefreshTokenService.call(params: params.to_unsafe_h)
#   in Success(access_token)          then render_success({ access_token: access_token })
#   in Failure[:invalid_token, msg]   then render_error(code: "invalid_token", message: msg, status: :unauthorized)
#   in Failure[:user_not_found, msg]  then render_error(code: "user_not_found", message: msg, status: :unauthorized)
#   end
class RefreshTokenService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(params:)
    @params = params
  end

  def call
    token   = @params.dig(:auth, :refresh_token).to_s
    payload = JwtService.decode(token)

    unless payload && payload["type"] == "refresh"
      return Failure[:invalid_token, I18n.t("errors.auth.invalid_token")]
    end

    user = User.find_by(id: payload["sub"])
    return Failure[:user_not_found, I18n.t("errors.auth.user_not_found")] unless user

    Success(JwtService.access_token(user))
  end
end
