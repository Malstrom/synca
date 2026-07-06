# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GuestRegistrationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          result = GuestRegistrationContract.new.call(params.to_unsafe_h)
          return render_contract_errors(result) if result.failure?

          email = result[:auth][:email]&.downcase

          user = User.find_by(email: email) if email

          if user&.active?
            return render_error(
              code: "email_already_active",
              message: "An active account with this email already exists"
            )
          end

          user ||= User.create!(
            email: email,
            auth_provider: :email,
            account_type: :guest
          )

          render_created({
            access_token: JwtService.access_token(user),
            token_type: "Bearer",
            expires_in: 2592000,
            account_type: user.account_type
          })
        end
      end
    end
  end
end
