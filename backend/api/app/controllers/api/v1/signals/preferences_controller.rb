# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        def create
          result = UpsertPreferencesService.new(current_user).call(preferences_params)

          if result.success?
            render json: PreferencesSerializer.new(result.value!).serializable_hash, status: :ok
          else
            render json: { error: { code: result.failure.first, message: result.failure.last } },
                   status: :unprocessable_entity
          end
        end

        private

        def preferences_params
          UpsertPreferencesContract.new.call(params)
        end
      end
    end
  end
end
