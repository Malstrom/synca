# frozen_string_literal: true

class SimulateMatchService
  include Dry::Monads[:result]

  def self.call(...) = new.call(...)

  def call(user_id:, other_user_id:)
    first_user  = User.find_by(id: user_id)
    second_user = User.find_by(id: other_user_id)

    unless first_user && second_user
      return Failure[:not_found, "One or both users not found"]
    end

    first_health  = first_user.health_summary
    second_health = second_user.health_summary

    result = if first_health && second_health
      CompatibilityService.call(first_health, second_health)
    else
      CompatibilityService::Result.new(
        total:       0.0,
        sleep:       0.0,
        activity:    0.0,
        lifestyle:   0.0,
        preferences: 0.0
      )
    end

    Success(result)
  end
end
