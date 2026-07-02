# frozen_string_literal: true

module Api
  module V1
    class SparkRewardsController < ApplicationController
      # GET /api/v1/spark_rewards
      def index
        rewards = current_user.spark_rewards.order(created_at: :desc)

        render_success({
          rewards: rewards.map { |reward| SparkRewardSerializer.new(reward).serialize }
        })
      end
    end
  end
end
