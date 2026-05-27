# frozen_string_literal: true

module Api
  module V1
    class SparkRewardsController < ApplicationController
      # GET /api/v1/spark_rewards
      def index
        rewards = current_user.spark_rewards.order(created_at: :desc)

        render json: {
          rewards: rewards.map { |reward|
            {
              id:           reward.id,
              reward_type:  reward.reward_type,
              status:       reward.status,
              valid_until:  reward.valid_until
            }
          }
        }
      end
    end
  end
end
