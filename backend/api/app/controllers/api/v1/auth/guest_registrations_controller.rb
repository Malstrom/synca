# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GuestRegistrationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          contract_result = GuestRegistrationContract.new.call(params.to_unsafe_h)

          if contract_result.failure?
            return render_error(
              code: "missing_params",
              message: contract_result.errors.to_h
            )
          end

          email = contract_result[:auth][:email]
          user = User.find_by(email: email, account_type: :guest) ||
                 User.find_by(email: email, account_type: :active)

          if user&.active?
            return render_error(
              code: "email_already_active",
              message: "Email is already associated with an active account"
            )
          end

          user ||= User.create!(
            email: email,
            auth_provider: :email,
            account_type: :guest
          )

          token = JwtService.access_token(user)

          render json: {
            access_token: token,
            token_type: "Bearer",
            expires_in: 2592000,
            account_type: user.account_type
          }, status: user.new_record? ? :created : :ok
        end
      end
    end
  end
end
