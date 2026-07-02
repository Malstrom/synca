# frozen_string_literal: true

module Api
  module V1
    module Auth
      class GuestRegistrationsController < ApplicationController
        skip_before_action :authenticate_user!

        def create
          email = params.dig(:auth, :email)

          if email.blank?
            return render_error(
              code: "missing_email",
              message: "Email is required"
            )
          end

          user = User.find_by(email: email.downcase)

          if user&.active?
            return render_error(
              code: "email_already_active",
              message: "An active account with this email already exists"
            )
          end

          user ||= User.create!(
            email: email.downcase,
            auth_provider: :email,
            account_type: :guest
          )

          token = JwtService.access_token(user)

          render_success(
            status: :created,
            data: {
              access_token: token,
              token_type: "Bearer",
              expires_in: 2592000,
              account_type: user.account_type
            }
          )
        end
      end
    end
  end
end
