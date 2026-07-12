# frozen_string_literal: true

class Api::V1::Auth::ResendMagicLinkController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    case ResendMagicLinkContract.new.call(params)
    in Success(attrs)
      case ResendMagicLinkService.call(attrs)
      in Success(_)
        render json: { message: I18n.t("resend_magic_link.success") }, status: :ok
      in Failure([:rate_limited, _])
        render json: { error: I18n.t("resend_magic_link.rate_limited") }, status: :too_many_requests
      end
    in Failure(errors)
      render json: { errors: errors }, status: :unprocessable_entity
    end
  end
end