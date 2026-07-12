# frozen_string_literal: true

class Api::V1::Auth::ResendMagicLinkController < Api::V1::BaseController
  include Dry::Monads[:result]

  def create
    case ResendMagicLinkContract.new.call(params)
    in Success(attrs)
      user = User.find_by(email: attrs[:email])

      if user && user.magic_link_sent_at && user.magic_link_sent_at > 5.minutes.ago
        render_error(status: :too_many_requests, code: :too_many_requests)
      else
        case MagicLinkService.call(user: user) if user
        in Success(user)
          GuestMailer.magic_link_email(user).deliver_later
        end

        render_success({ message: I18n.t("controllers.api.v1.auth.resend_magic_link.success") })
      end
    in Failure(errors)
      render_error(status: :unprocessable_entity, errors: errors)
    end
  end
end