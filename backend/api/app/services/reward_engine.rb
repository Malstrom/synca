# frozen_string_literal: true

# Issues one SparkReward per participant after a Spark is completed.
# Idempotent: calling it twice on the same spark is a no-op.
class RewardEngine
  def self.call(spark)
    new(spark).call
  end

  def initialize(spark)
    @spark = spark
  end

  def call
    return if @spark.reward_issued_initiator && @spark.reward_issued_partner

    issue_reward_for(@spark.initiator) unless @spark.reward_issued_initiator
    issue_reward_for(@spark.partner)   unless @spark.reward_issued_partner

    @spark.update!(
      reward_issued_initiator: true,
      reward_issued_partner:   true
    )
  end

  private

    def issue_reward_for(user)
      reward_type  = resolve_reward_type(user)
      valid_days   = Settings.rewards.valid_days[reward_type]

      SparkReward.create!(
        user:        user,
        spark:       @spark,
        reward_type: reward_type,
        status:      :pending,
        valid_until: valid_days.days.from_now
      )
    end

    # Free users receive premium_week. Premium logic can be extended here.
    def resolve_reward_type(_user)
      :premium_week
    end
end
