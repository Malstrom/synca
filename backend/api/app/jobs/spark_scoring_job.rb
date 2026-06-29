# frozen_string_literal: true

class SparkScoringJob < ApplicationJob
  queue_as :spark

  def perform(spark_session_id)
    spark_session = SparkSession.find_by(id: spark_session_id)
    return unless spark_session
    return if spark_session.completed?

    initiator_health = spark_session.initiator.health_summary
    partner_health   = spark_session.partner&.health_summary

    # Product decision (signals-partial-spark-scoring): in MVP lo Spark è bloccato
    # se Apple Health non è connesso. Non esiste fallback score "di default".
    unless initiator_health && partner_health
      spark_session.update!(status: :expired)
      return
    end

    compatibility_result = CompatibilityService.call(initiator_health, partner_health)

    spark_session.update!(
      status:              :completed,
      completed_at:        Time.current,
      compatibility_score: compatibility_result.total
    )

    RewardEngine.call(spark_session)
  end
end
