# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivationsController < ApplicationController
        include Dry::Monads[:result]

        def create
          case ActivateGuestService.call(
            token: params[:token],
            display_name: params.dig(:profile, :display_name)
          )
          in Success(tokens)
            render_success(tokens)
          in Failure([:token_expired, message])
            render_error(:unprocessable_entity, message, code: "token_expired")
          in Failure([:token_already_used, message])
            render_error(:unprocessable_entity, message, code: "token_already_used")
          in Failure([:account_already_active, message])
            render_error(:unprocessable_entity, message, code: "account_already_active")
          in Failure([:validation_failed, message])
            render_error(:unprocessable_entity, message, code: "validation_failed")
          in Failure([:invalid_token, message])
            render_error(:unprocessable_entity, message, code: "invalid_token")
          end
        end
      end
    end
  end
end
