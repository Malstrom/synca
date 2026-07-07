# frozen_string_literal: true

class AddDeclaredPreferencesToPreferenceProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :preference_profiles, :sleep_together_importance, :integer
    add_column :preference_profiles, :temperature_preference, :integer
    add_column :preference_profiles, :movement_preference, :integer
    add_column :preference_profiles, :rhythm_importance, :integer
    add_column :preference_profiles, :self_chronotype, :integer
  end
end
