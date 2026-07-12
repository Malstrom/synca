# frozen_string_literal: true

class Api::V1::Auth::ResendMagicLinkController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    user = User.find_by(email: params[:email])

    if user
      case MagicLinkService.call(user: user)
      in Success(_)
        # Do nothing - we always return the same message
      in Failure([:rate_limited, _])
        render json: { error: I18n.t("services.magic_link.rate_limited") }, status: :too_many_requests
        return
      end
    end

    render json: { message: I18n.t("services.magic_link.resend_success") }, status: :ok
  end
end