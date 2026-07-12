# frozen_string_literal: true

module Api
  module V1
    module Auth
      class ActivateController < Api::V1::BaseController
        include Dry::Monads[:result]

        def create
          result = ActivateContract.new.call(params)

          case result
          in Success
            user = User.find_by(magic_link_token: params[:token])
            user.update!(account_type: :active, magic_link_token: nil)
            user.profile.update!(display_name: params[:profile][:display_name])

            render_success({ access_token: JwtService.access_token(user),
                             refresh_token: JwtService.refresh_token(user),
                             token_type: "Bearer",
                             account_type: user.account_type })
          in Failure(errors)
            render_error(errors, status: :unprocessable_entity)
          end
        end
      end
    end
  end
end