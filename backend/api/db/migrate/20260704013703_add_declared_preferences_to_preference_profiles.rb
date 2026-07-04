# frozen_string_literal: true

class AddDeclaredPreferencesToPreferenceProfiles < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :preference_profiles, :sleep_together_importance, :integer, limit: 2
    add_column :preference_profiles, :temperature_preference, :integer, limit: 2
    add_column :preference_profiles, :movement_preference, :integer, limit: 2
    add_column :preference_profiles, :rhythm_importance, :integer, limit: 2
    add_column :preference_profiles, :self_chronotype, :integer, limit: 2

    add_index :preference_profiles, :sleep_together_importance, algorithm: :concurrently
    add_index :preference_profiles, :temperature_preference, algorithm: :concurrently
    add_index :preference_profiles, :movement_preference, algorithm: :concurrently
    add_index :preference_profiles, :rhythm_importance, algorithm: :concurrently
    add_index :preference_profiles, :self_chronotype, algorithm: :concurrently
  end
end
