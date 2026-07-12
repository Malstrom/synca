# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_request

        def create
          user = User.find_by(magic_link_token: params[:token])

          if user.nil?
            render json: { error: I18n.t("errors.token_not_found") }, status: :not_found
            return
          end

          if user.active?
            render json: { error: I18n.t("errors.account_already_active") }, status: :unprocessable_entity
            return
          end

          if user.magic_link_expired?
            render json: { error: I18n.t("errors.token_expired") }, status: :unprocessable_entity
            return
          end

          if user.magic_link_token.nil?
            render json: { error: I18n.t("errors.token_already_used") }, status: :unprocessable_entity
            return
          end

          profile_attrs = params.require(:profile).permit(:display_name)
          profile = user.build_profile(profile_attrs)

          if profile.save
            user.update!(
              account_type: :active,
              magic_link_token: nil,
              magic_link_sent_at: nil
            )

            tokens = JwtService.encode(user_id: user.id)
            render json: {
              access_token: tokens[:access_token],
              refresh_token: tokens[:refresh_token],
              token_type: "Bearer",
              account_type: "active"
            }, status: :ok
          else
            render json: { error: profile.errors.full_messages.first }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
