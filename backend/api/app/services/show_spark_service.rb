# frozen_string_literal: true

# Returns a single Spark to one of its participants. Backs the initiator's
# poll while the QR is on screen ("has anyone joined yet?") — `result` can't
# serve that, it 422s until both sides have answered and scoring has run.
#
# @example
#   case ShowSparkService.call(current_user: current_user, spark: @spark)
#   in Success(spark)               then render_success(SparkSerializer.new(spark).serialize)
#   in Failure[:not_participant, m] then render_error(code: "forbidden", message: m, status: :forbidden)
#   end
class ShowSparkService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:, spark:)
    @current_user = current_user
    @spark        = spark
  end

  def call
    unless @spark.initiator_id == @current_user.id || @spark.partner_id == @current_user.id
      return Failure[:not_participant, I18n.t("errors.spark.not_participant")]
    end

    Success(@spark)
  end
end
