# frozen_string_literal: true

# Builds the result payload for a completed Spark.
# Verifies the spark is completed and the requesting user is a participant.
#
# @example
#   case SparkResultService.call(spark: @spark, current_user: current_user)
#   in Success(result)                  then render_success(result)
#   in Failure[:spark_not_completed, m] then render_error(code: "spark_not_completed", ...)
#   in Failure[:not_participant, m]     then render_error(code: "forbidden", ...)
#   end
class SparkResultService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(spark:, current_user:)
    @spark        = spark
    @current_user = current_user
  end

  def call
    unless @spark.initiator_id == @current_user.id || @spark.partner_id == @current_user.id
      return Failure[:not_participant, I18n.t("errors.spark.not_participant")]
    end

    unless @spark.completed?
      return Failure[:spark_not_completed, I18n.t("errors.spark.spark_not_completed")]
    end

    rewards    = SparkReward.where(spark: @spark)
    dimensions = build_dimensions

    Success({
      compatibility_score: @spark.compatibility_score,
      dimensions:          dimensions,
      rewards:             rewards.map { |r| { type: r.reward_type, status: r.status } }
    })
  end

  private

  def build_dimensions
    initiator_health = @spark.initiator.health_summary
    partner_health   = @spark.partner&.health_summary
    return {} unless initiator_health && partner_health

    result = CompatibilityService.call(initiator_health, partner_health)
    {
      sleep_rhythm:   result.sleep,
      energy_overlap: result.activity,
      lifestyle:      result.lifestyle
    }
  end
end
