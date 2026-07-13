# frozen_string_literal: true

module Api
  module V1
    class ProfileController < ApplicationController
      # PUT /api/v1/me/profile
      def update
        case UpdateProfileService.call(
          current_user: current_user,
          params: params.to_unsafe_h
        )
        in Success[profile]
          render_success({ profile: ProfileSerializer.new(profile).serializable_hash })
        in Failure[:contract_invalid, result]
          render_contract_errors(result)
        in Failure[:validation_failed, message]
          render_error(code: "validation_failed", message: message)
        end
      end
    end
  end
end
