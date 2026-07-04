# frozen_string_literal: true

class AddDeclaredPreferencesToPreferenceProfiles < ActiveRecord::Migration[7.1]
  def change
    change_table :preference_profiles, bulk: true do |t|
      t.integer :sleep_together_importance
      t.integer :temperature_preference
      t.integer :movement_preference
      t.integer :rhythm_importance
      t.integer :self_chronotype
    end
  end
end
