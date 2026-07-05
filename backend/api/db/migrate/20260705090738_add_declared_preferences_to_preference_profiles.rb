# frozen_string_literal: true

class AddDeclaredPreferencesToPreferenceProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :preference_profiles, :sleep_together_importance, :integer, null: true
    add_column :preference_profiles, :temperature_preference, :integer, null: true
    add_column :preference_profiles, :movement_preference, :integer, null: true
    add_column :preference_profiles, :rhythm_importance, :integer, null: true
    add_column :preference_profiles, :self_chronotype, :integer, null: true
  end
end
