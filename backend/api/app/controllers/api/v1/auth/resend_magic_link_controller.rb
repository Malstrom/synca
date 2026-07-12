# frozen_string_literal: true

class Api::V1::Auth::ResendMagicLinkController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    case ResendMagicLinkContract.new.call(params)
    in Success(attrs)
      case ResendMagicLinkService.call(email: attrs[:email])
      in Success(_)
        render_success({ message: I18n.t("resend_magic_link.success") })
      in Failure([:rate_limited, _])
        render_error(status: :too_many_requests, code: :rate_limited)
      end
    in Failure(errors)
      render_error(status: :unprocessable_entity, errors: errors)
    end
  end
end