# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        before_action :authenticate!

        def create
          result = UpsertPreferencesContract.new.call(params)

          if result.success?
            preferences_result = UpsertPreferencesService.call(
              current_user:,
              attrs: result.to_h[:preferences] || {}
            )

            if preferences_result.success?
              render json: {
                preferences: PreferencesSerializer.new(preferences_result.value!).to_h
              }, status: :ok
            else
              render json: {
                error: {
                  code: preferences_result.failure.first,
                  message: preferences_result.failure.last
                }
              }, status: :unprocessable_entity
            end
          else
            render json: {
              error: {
                code: :validation_failed,
                message: result.errors(full: true).to_h.inspect
              }
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
