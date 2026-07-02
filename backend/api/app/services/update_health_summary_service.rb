# frozen_string_literal: true

# Updates (or creates) the HealthSummary for a given user.
# Returns Success(health_summary) or Failure([:validation_failed, message]).
class UpdateHealthSummaryService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(current_user:, attrs:)
    health_summary = current_user.health_summary || current_user.build_health_summary

    if health_summary.update(attrs)
      Success(health_summary)
    else
      Failure([ :validation_failed, health_summary.errors.full_messages.first ])
    end
  end
end
