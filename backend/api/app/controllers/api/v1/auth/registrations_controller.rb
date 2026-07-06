# frozen_string_literal: true

module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        skip_before_action :authenticate_user!

        # POST /api/v1/auth/register
        def create
          result = RegistrationContract.new.call(params.to_unsafe_h)
          return render_contract_errors(result) if result.failure?

          user = User.create!(
            email:         result[:auth][:email]&.downcase,
            phone:         result[:auth][:phone],
            password:      result[:auth][:password],
            provider_uid:  result[:auth][:provider_uid],
            auth_provider: result[:auth][:auth_provider]
          )

          render_created(auth_response(user))
        end
      end
    end
  end
end
