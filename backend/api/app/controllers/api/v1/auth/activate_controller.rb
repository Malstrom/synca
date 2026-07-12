# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivateController < ApplicationController
        include Dry::Monads[:result]

        def create
          case ActivateService.call(token: params[:token], display_name: params.dig(:profile, :display_name))
          in Success(user)
            render_success({ user: UserSerializer.new(user).as_json })
          in Failure([:token_expired, _])
            render_error(status: :unprocessable_entity, code: :token_expired)
          in Failure([:token_already_used, _])
            render_error(status: :unprocessable_entity, code: :token_already_used)
          in Failure([:account_already_active, _])
            render_error(status: :unprocessable_entity, code: :account_already_active)
          in Failure([:not_found, _])
            render_error(status: :not_found, code: :not_found)
          end
        end
      end
    end
  end
end
