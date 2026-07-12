# frozen_string_literal: true

class Api::V1::Auth::ActivateController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    case ActivateContract.new.call(params)
    in Success(attrs)
      case ActivateService.call(attrs)
      in Success(user)
        render json: TokenResponseSerializer.new(JwtService.access_token(user)), status: :ok
      in Failure([:token_expired, _])
        render json: { error: I18n.t("contracts.errors.token.token_expired") }, status: :unprocessable_entity
      in Failure([:token_already_used, _])
        render json: { error: I18n.t("contracts.errors.token.token_already_used") }, status: :unprocessable_entity
      in Failure([:account_already_active, _])
        render json: { error: I18n.t("contracts.errors.token.account_already_active") }, status: :unprocessable_entity
      in Failure([:not_found, _])
        render json: { error: I18n.t("contracts.errors.token.not_found") }, status: :not_found
      end
    in Failure(errors)
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end
end
