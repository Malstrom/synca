# frozen_string_literal: true

module Api
  module V1
    module Signals
      class PreferencesController < ApplicationController
        before_action :authenticate_user!

        def create
          contract = UpsertPreferencesContract.new.call(params)

          if contract.success?
            result = UpsertPreferencesService.new.call(user: current_user, params: contract.to_h)

            if result.success?
              render json: PreferencesSerializer.new(result.value!).serializable_hash, status: :ok
            else
              render json: { error: { code: result.failure.first, message: result.failure.last } }, status: :unprocessable_entity
            end
          else
            render json: { error: { code: :validation_failed, message: contract.errors.to_h } }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
