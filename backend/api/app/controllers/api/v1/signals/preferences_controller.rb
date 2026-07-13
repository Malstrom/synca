# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        include Dry::Monads[:result]

        def upsert
          case UpsertPreferencesService.call(current_user: current_user, params: params.to_unsafe_h)
          in Success(preference_profile)
            render_success(PreferencesSerializer.new(preference_profile).serializable_hash)
          in Failure[:contract_invalid, result]
            render_contract_errors(result)
          in Failure[:validation_failed, message]
            render_error(code: "validation_failed", message: message)
          end
        end
      end
    end
  end
end
