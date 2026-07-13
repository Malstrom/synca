# frozen_string_literal: true

# Scores a Spark and issues rewards after completion.
# Idempotent: with_lock + re-check completed? prevents double-scoring.
class SparkScoringService
  def self.call(spark_id)
    new(spark_id).call
  end

  def initialize(spark_id)
    @spark_id = spark_id
  end

  def call
    spark = Spark.find_by(id: @spark_id)
    return unless spark

    spark.with_lock do
      return if spark.completed?

      score = compatibility_score(spark)

      ActiveRecord::Base.transaction do
        spark.update!(
          status:              :completed,
          completed_at:        Time.current,
          compatibility_score: score
        )

        RewardEngine.call(spark)
      end
    end
  end

  private

    def compatibility_score(spark)
      initiator_health = spark.initiator.health_summary
      partner_health   = spark.partner.health_summary

      if initiator_health && partner_health
        CompatibilityService.call(initiator_health, partner_health).total
      else
        Settings.spark.fallback_score
      end
    end
end
