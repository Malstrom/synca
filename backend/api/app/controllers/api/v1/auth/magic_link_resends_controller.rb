# frozen_string_literal: true

class Api::V1::Auth::MagicLinkResendsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    user = User.find_by(email: params[:email])

    if user&.guest?
      result = MagicLinkService.resend(user: user)

      case result
      in Success(_)
        render json: { message: I18n.t("services.magic_link.resend_success") }, status: :ok
      in Failure([:rate_limited, _])
        render json: { error: I18n.t("services.magic_link.rate_limited") }, status: :too_many_requests
      in Failure([:invalid_record, _])
        render json: { error: I18n.t("services.magic_link.invalid_record") }, status: :unprocessable_entity
      end
    else
      render json: { message: I18n.t("services.magic_link.resend_success") }, status: :ok
    end
  end
end
