# frozen_string_literal: true

# Issues one SparkReward per participant after a SparkSession is completed.
# Idempotent: calling it twice on the same session is a no-op.
class RewardEngine
  REWARD_VALID_DAYS = {
    premium_week:  7,
    match_credit:  30,
    boost:         7
  }.freeze

  def self.call(spark_session)
    new(spark_session).call
  end

  def initialize(spark_session)
    @spark_session = spark_session
  end

  def call
    return if @spark_session.reward_issued_initiator && @spark_session.reward_issued_partner

    issue_reward_for(@spark_session.initiator) unless @spark_session.reward_issued_initiator
    issue_reward_for(@spark_session.partner)   unless @spark_session.reward_issued_partner

    @spark_session.update!(
      reward_issued_initiator: true,
      reward_issued_partner:   true
    )
  end

  private

    def issue_reward_for(user)
      reward_type = resolve_reward_type(user)

      SparkReward.create!(
        user:          user,
        spark_session: @spark_session,
        reward_type:   reward_type,
        status:        :pending,
        valid_until:   REWARD_VALID_DAYS[reward_type].days.from_now
      )
    end

    # Free users receive premium_week. Premium logic can be extended here.
    def resolve_reward_type(user)
      :premium_week
    end
end
