# frozen_string_literal: true

module Api
  module V1
    class SparkRewardsController < ApplicationController
      # GET /api/v1/spark_rewards
      def index
        case ListSparkRewardsService.call(current_user: current_user)
        in Success[rewards]
          render_success({ rewards: rewards.map { |r| SparkRewardSerializer.new(r).serialize } })
        end
      end
    end
  end
end
