# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/register
        def create
          user = User.new(register_params)

          unless user.save
            return render_validation_errors(user)
          end

          render_created(auth_response(user))
        end

        private

          def register_params
            params.require(:auth).permit(:email, :phone, :password, :auth_provider, :provider_uid)
          end
      end
    end
  end
end
