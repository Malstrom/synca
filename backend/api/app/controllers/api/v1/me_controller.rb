# frozen_string_literal: true

module Api
  module V1
    class MeController < ApplicationController
      # GET /api/v1/me
      def show
        render_success(MeSerializer.new(current_user).serialize)
      end
    end
  end
end
