# frozen_string_literal: true

class AddDeclaredPreferencesToPreferenceProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :preference_profiles, :sleep_together_importance, :integer,
      comment: "Likert 1-5: how important is sleeping together"
    add_column :preference_profiles, :temperature_preference, :integer,
      comment: "enum: cool=0, warm=1, no_preference=2"
    add_column :preference_profiles, :movement_preference, :integer,
      comment: "enum: very_little=0, moderate=1, a_lot=2, as_much_as_possible=3"
    add_column :preference_profiles, :rhythm_importance, :integer,
      comment: "Likert 1-5: how important is shared daily rhythm"
    add_column :preference_profiles, :self_chronotype, :integer,
      comment: "enum: morning=0, night=1, depends=2"

    remove_column :preference_profiles, :travel_style, :integer
  end
end
