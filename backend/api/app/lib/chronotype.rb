# frozen_string_literal: true

# Domain vocabulary for chronotype values.
# Single source of truth for labels, tier mappings, and self-report cross-references.
# Used by services, serializers, and jobs — do not duplicate these mappings elsewhere.
module Chronotype
  LABELS = {
    "early_bird"   => "Early bird",
    "intermediate" => "Flexible",
    "night_owl"    => "Night owl"
  }.freeze

  # Maps declared self-chronotype (PreferenceProfile) to observed chronotype (HealthSummary).
  SELF_TO_OBSERVED = {
    "morning" => "early_bird",
    "night"   => "night_owl"
  }.freeze

  ROUTINE_STABILITY_TIERS = [
    [0.0...0.4, "low"],
    [0.4...0.7, "medium"],
    [0.7..1.0,  "high"]
  ].freeze

  def self.label(value)
    LABELS.fetch(value) { raise ArgumentError, "Unknown chronotype: #{value.inspect}" }
  end

  def self.routine_stability_tier(index)
    ROUTINE_STABILITY_TIERS.find { |range, _| range.cover?(index) }&.last
  end

  def self.observed_from_self(self_chronotype)
    SELF_TO_OBSERVED[self_chronotype]
  end
end
