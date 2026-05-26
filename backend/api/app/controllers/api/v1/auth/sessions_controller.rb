module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/login
        def create
          user = User.find_by(email: params.dig(:auth, :email)&.downcase)

          unless user&.authenticate(params.dig(:auth, :password))
            return render_error(
              code: "invalid_credentials",
              message: "Invalid email or password",
              status: :unauthorized
            )
          end

          render_success(auth_response(user))
        end
      end
    end
  end
end
