# frozen_string_literal: true

class RevertDeclaredPreferences < ActiveRecord::Migration[7.1]
  def up
    # Remove the columns added in AddDeclaredPreferencesToPreferenceProfiles
    remove_column :preference_profiles, :sleep_together_importance, :integer
    remove_column :preference_profiles, :temperature_preference, :integer
    remove_column :preference_profiles, :movement_preference, :integer
    remove_column :preference_profiles, :rhythm_importance, :integer
    remove_column :preference_profiles, :self_chronotype, :integer
  end

  def down
    # Re-add the columns if needed
    add_column :preference_profiles, :sleep_together_importance, :integer, null: true
    add_column :preference_profiles, :temperature_preference, :integer, null: true
    add_column :preference_profiles, :movement_preference, :integer, null: true
    add_column :preference_profiles, :rhythm_importance, :integer, null: true
    add_column :preference_profiles, :self_chronotype, :integer, null: true
  end
end
