# frozen_string_literal: true

class SignalsSummarySerializer
  include Alba::Resource

  attribute :chronotype_label do |obj|
    I18n.t("chronotypes.#{obj.chronotype}")
  end

  attribute :peak_energy_window do |obj|
    obj.peak_energy_start_local && obj.peak_energy_end_local ? "#{obj.peak_energy_start_local}–#{obj.peak_energy_end_local}" : nil
  end

  attribute :routine_stability_tier do |obj|
    case obj.routine_stability_index
    when 0.0...0.4 then "low"
    when 0.4...0.7 then "medium"
    when 0.7..1.0  then "high"
    end
  end

  attribute :activity_tier do |obj|
    obj.activity_level
  end

  attribute :avg_sleep_duration_minutes do |obj|
    (obj.sleep_duration_avg * 60).to_i
  end

  attribute :self_report_alignment do |obj|
    next nil unless obj.preference_profile&.self_chronotype

    self_chronotype = obj.preference_profile.self_chronotype
    aligned = self_chronotype == "depends" ||
              (self_chronotype == "morning" && obj.chronotype == "early_bird") ||
              (self_chronotype == "night" && obj.chronotype == "night_owl")

    {
      aligned: aligned,
      note: aligned ? nil : I18n.t("self_report_alignment.note", self_chronotype: self_chronotype, chronotype: obj.chronotype)
    }
  end
end