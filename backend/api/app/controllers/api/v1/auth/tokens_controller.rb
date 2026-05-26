module Api
  module V1
    module Auth
      class TokensController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/refresh
        def create
          token   = params.dig(:auth, :refresh_token)
          payload = JwtService.decode(token.to_s)

          if payload.nil? || payload["type"] != "refresh"
            return render_error(
              code: "invalid_token",
              message: "Invalid or expired refresh token",
              status: :unauthorized
            )
          end

          user = User.find_by(id: payload["sub"])
          return render_unauthorized unless user

          render_success({ access_token: JwtService.access_token(user) })
        end
      end
    end
  end
end
