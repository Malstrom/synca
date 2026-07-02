# frozen_string_literal: true

module Api
  module V1
    class ProfileController < ApplicationController
      include Dry::Monads[:result]

      # PUT /api/v1/me/profile
      def update
        contract_result = ProfileContract.new.call(profile: params[:profile]&.to_unsafe_h || {})

        if contract_result.failure?
          first_error = contract_result.errors.to_h.values.flatten.first
          return render json: {
            error: { code: "validation_failed", message: first_error }
          }, status: :unprocessable_entity
        end

        profile = current_user.profile || current_user.build_profile

        unless profile.update(contract_result.to_h[:profile])
          return render json: {
            error: { code: "validation_failed", message: profile.errors.full_messages.first }
          }, status: :unprocessable_entity
        end

        render_success({ profile: ProfileSerializer.new(profile).serialize })
      end
    end
  end
end
