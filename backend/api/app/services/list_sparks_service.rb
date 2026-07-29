# frozen_string_literal: true

# Lists every Spark the user took part in, newest first — either side of it.
# Backs the Dashboard's "YOUR SPARKS" list, so it returns the scored history
# (see SparkHistorySerializer), not the join credentials SparkSerializer carries.
#
# @example
#   case ListSparksService.call(current_user: current_user)
#   in Success[sparks] then render_success({ sparks: sparks.map { |s| SparkHistorySerializer.new(s).serializable_hash } })
#   end
class ListSparksService
  include Dry::Monads[:result]

  def self.call(...) = new(...).call

  def initialize(current_user:)
    @current_user = current_user
  end

  def call
    sparks = Spark
      .where(initiator: @current_user)
      .or(Spark.where(partner: @current_user))
      .order(created_at: :desc)

    Success[sparks]
  end
end
