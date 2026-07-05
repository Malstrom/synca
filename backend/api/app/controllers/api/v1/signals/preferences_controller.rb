# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        before_action :authenticate_user!

        def create
          result = UpsertPreferencesContract.new.call(params)

          if result.success?
            service_result = UpsertPreferencesService.new.call(user: current_user, params: result.to_h)

            if service_result.success?
              render json: PreferencesSerializer.new(service_result.value!).serialize, status: :ok
            else
              render json: { error: { code: service_result.failure.first, message: service_result.failure.last } }, status: :unprocessable_entity
            end
          else
            render json: { error: { code: :validation_failed, message: result.errors.to_h } }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
