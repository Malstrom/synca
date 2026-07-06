# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        include Dry::Monads[:result]

        # POST /api/v1/signals/preferences
        def create
          contract_result = UpsertPreferencesContract.new.call(
            preferences: params[:preferences].to_h
          )

          return render_contract_errors(contract_result) if contract_result.failure?

          case UpsertPreferencesService.call(current_user: current_user, attrs: contract_result.to_h[:preferences])
          in Success[preference_profile]
            render_success({ preferences: PreferencesSerializer.new(preference_profile).serializable_hash })
          in Failure[:validation_failed, message]
            render_error(code: 'validation_failed', message: message)
          end
        end
      end
    end
  end
end
