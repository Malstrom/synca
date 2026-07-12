# frozen_string_literal: true

class Api::V1::Auth::ActivateController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    case MagicLinkService.call(user: user)
    in Success(user)
      render json: JwtService.access_token(user), status: :ok
    in Failure([:token_expired, _])
      render json: { error: I18n.t("services.magic_link.token_expired") }, status: :unprocessable_entity
    in Failure([:token_already_used, _])
      render json: { error: I18n.t("services.magic_link.token_already_used") }, status: :unprocessable_entity
    in Failure([:account_already_active, _])
      render json: { error: I18n.t("services.magic_link.account_already_active") }, status: :unprocessable_entity
    in Failure([:error, _])
      render json: { error: I18n.t("errors.generic") }, status: :internal_server_error
    end
  end

  private

  def user
    @user ||= User.find_by(magic_link_token: params[:token])
  end
end