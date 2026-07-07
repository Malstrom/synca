# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        include Dry::Monads[:result]

        # PATCH /api/v1/signals/preferences
        def upsert
          contract_result = UpsertPreferencesContract.new.call(
            preferences: params[:preferences]&.to_unsafe_h&.deep_symbolize_keys
          )

          return render_contract_errors(contract_result) if contract_result.failure?

          result = UpsertPreferencesService.call(
            current_user: current_user,
            attrs: contract_result.to_h[:preferences]
          )

          case result
          in Success[ preference_profile ]
            render_success(PreferencesSerializer.new(preference_profile).serializable_hash)
          in Failure[ :validation_failed, message ]
            render_error(code: "validation_failed", message: message)
          end
        end
      end
    end
  end
end
