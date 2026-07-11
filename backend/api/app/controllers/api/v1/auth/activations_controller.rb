# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def create
          result = ActivateContract.new.call(params)

          case result
          in Success(attrs)
            user = User.find_by(magic_link_token: attrs[:token])

            if user.nil?
              render_error(:not_found, I18n.t("controllers.activations.not_found"))
            elsif user.magic_link_sent_at.nil? || user.magic_link_sent_at < 72.hours.ago
              render_error(:unprocessable_entity, I18n.t("controllers.activations.token_expired"))
            elsif user.magic_link_token.nil?
              render_error(:unprocessable_entity, I18n.t("controllers.activations.token_already_used"))
            elsif user.account_type == "active"
              render_error(:unprocessable_entity, I18n.t("controllers.activations.account_already_active"))
            else
              user.update!(
                account_type: :active,
                magic_link_token: nil
              )
              user.profile.update!(display_name: attrs.dig(:profile, :display_name))

              access_token = JwtService.access_token(user)
              refresh_token = JwtService.refresh_token(user)

              render_success({
                access_token: access_token,
                refresh_token: refresh_token,
                token_type: "Bearer",
                account_type: user.account_type
              })
            end
          in Failure(errors)
            render_error(:unprocessable_entity, errors.to_h)
          end
        end
      end
    end
  end
end
