# frozen_string_literal: true

# Issues one SparkReward per participant after a Spark is completed.
# Idempotent: the unique index on (user_id, spark_id) is the guard —
# create_or_find_by silently skips duplicates on retry.
class RewardEngine
  def self.call(spark)
    new(spark).call
  end

  def initialize(spark)
    @spark = spark
  end

  def call
    return if @spark.reward_issued_initiator && @spark.reward_issued_partner

    ActiveRecord::Base.transaction do
      @spark.lock!

      unless @spark.reward_issued_initiator
        issue_reward_for(@spark.initiator)
        @spark.update_columns(reward_issued_initiator: true)
      end

      unless @spark.reward_issued_partner
        issue_reward_for(@spark.partner)
        @spark.update_columns(reward_issued_partner: true)
      end
    end
  end

  private

    def issue_reward_for(user)
      reward_type = resolve_reward_type(user)
      valid_days  = Settings.rewards.valid_days[reward_type]

      SparkReward.create_or_find_by!(user: user, spark: @spark) do |r|
        r.reward_type = reward_type
        r.status      = :pending
        r.valid_until = valid_days.days.from_now
      end
    end

    # Free users receive premium_week. Premium logic can be extended here.
    def resolve_reward_type(_user)
      :premium_week
    end
end
