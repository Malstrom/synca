# frozen_string_literal: true

class ListSparkRewardsService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:)
    @current_user = current_user
  end

  def call
    Success[@current_user.spark_rewards.order(created_at: :desc)]
  end
end
