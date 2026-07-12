# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def create
          case MagicLinkService.validate_token(token: params[:token])
          in Success(user)
            case activate_user(user: user, display_name: params.dig(:profile, :display_name))
            in Success(user)
              render_success({
                access_token: JwtService.access_token(user),
                refresh_token: JwtService.refresh_token(user),
                token_type: "Bearer",
                account_type: user.account_type
              })
            in Failure([:validation_failed, message])
              render_error(status: :unprocessable_entity, message: message)
            end
          in Failure([:token_not_found, message])
            render_error(status: :not_found, message: message)
          in Failure([:token_expired, message])
            render_error(status: :unprocessable_entity, message: message)
          in Failure([:token_already_used, message])
            render_error(status: :unprocessable_entity, message: message)
          in Failure([:account_already_active, message])
            render_error(status: :unprocessable_entity, message: message)
          end
        end

        private

          def activate_user(user:, display_name:)
            user.transaction do
              user.update!(account_type: :active, magic_link_token: nil)
              user.profile.update!(display_name: display_name)
            end

            Success(user)
          rescue ActiveRecord::RecordInvalid => e
            Failure([:validation_failed, e.message])
          end
      end
    end
  end
end
