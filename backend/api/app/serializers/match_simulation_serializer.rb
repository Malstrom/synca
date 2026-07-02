# frozen_string_literal: true

class MatchSimulationSerializer
  include Alba::Resource

  attributes :compatibility_score, :dimensions

  attribute :compatibility_score do |result|
    result.total
  end

  attribute :dimensions do |result|
    {
      sleep_rhythm:   result.sleep,
      energy_overlap: result.activity,
      lifestyle:      result.lifestyle
    }
  end
end
