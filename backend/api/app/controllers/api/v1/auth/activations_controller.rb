# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        skip_before_action :authenticate_request

        def create
          user = User.find_by(magic_link_token: params[:token])

          if user.nil?
            render json: { error: "Token not found" }, status: :not_found
            return
          end

          if user.account_type == "active"
            render json: { error: "Account already active" }, status: :unprocessable_entity
            return
          end

          if user.magic_link_sent_at < 72.hours.ago
            render json: { error: "Token expired" }, status: :unprocessable_entity
            return
          end

          if user.magic_link_token.nil?
            render json: { error: "Token already used" }, status: :unprocessable_entity
            return
          end

          user.update!(
            account_type: :active,
            magic_link_token: nil,
            magic_link_sent_at: nil
          )

          profile = user.profile || user.build_profile
          profile.update!(display_name: params[:profile][:display_name])

          tokens = JwtService.call(user: user)

          render json: {
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token],
            token_type: "Bearer",
            account_type: "active"
          }, status: :ok
        end
      end
    end
  end
end