# frozen_string_literal: true

module Api
  module V1
    class SparkRewardsController < ApplicationController
      include Dry::Monads[:result]

      def index
        case ListSparkRewardsService.call(current_user: current_user)
        in Success[rewards]
          render_success({ rewards: rewards.map { |r| SparkRewardSerializer.new(r).serialize } })
        end
      end
    end
  end
end
