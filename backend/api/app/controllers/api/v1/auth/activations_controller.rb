# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_request

        def create
          case MagicLinkService.new.activate(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render_success({ user: UserSerializer.new(user).as_json })
          in Failure([:token_not_found, _])
            render_not_found(I18n.t("controllers.auth.activations.token_not_found"))
          in Failure([:token_expired, _])
            render_unprocessable_entity(I18n.t("controllers.auth.activations.token_expired"))
          in Failure([:account_already_active, _])
            render_unprocessable_entity(I18n.t("controllers.auth.activations.account_already_active"))
          end
        end
      end
    end
  end
end