# frozen_string_literal: true

# Returns the ordered list of SparkRewards for the current user.
class ListSparkRewardsService
  include Dry::Monads[:result]

  def self.call(**args) = new(**args).call

  def initialize(current_user:)
    @current_user = current_user
  end

  def call
    rewards = @current_user.spark_rewards.order(created_at: :desc)
    Success[rewards]
  end
end
