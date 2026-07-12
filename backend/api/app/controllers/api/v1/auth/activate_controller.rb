# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivateController < Api::V1::BaseController
        include Dry::Monads[:result]

        def create
          case ActivateContract.new.call(params)
          in Success(attrs)
            case ActivateService.call(attrs: attrs)
            in Success(user)
              render_success({ user: UserSerializer.new(user).as_json })
            in Failure([:token_expired, _])
              render_error(status: :unprocessable_entity, code: :token_expired)
            in Failure([:token_already_used, _])
              render_error(status: :unprocessable_entity, code: :token_already_used)
            in Failure([:account_already_active, _])
              render_error(status: :unprocessable_entity, code: :account_already_active)
            in Failure([:token_not_found, _])
              render_error(status: :not_found, code: :token_not_found)
            end
          in Failure(errors)
            render_error(status: :unprocessable_entity, errors: errors)
          end
        end
      end
    end
  end
end