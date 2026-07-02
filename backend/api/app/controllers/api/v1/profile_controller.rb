# frozen_string_literal: true

module Api
  module V1
    class ProfileController < ApplicationController
      include Dry::Monads[:result]

      # PUT /api/v1/me/profile
      def update
        contract_result = ProfileContract.new.call(profile: params[:profile]&.to_unsafe_h || {})

        return render_contract_errors(contract_result) if contract_result.failure?

        profile = current_user.profile || current_user.build_profile

        unless profile.update(contract_result.to_h[:profile])
          return render_validation_errors(profile)
        end

        render_success({ profile: ProfileSerializer.new(profile).serializable_hash })
      end
    end
  end
end
