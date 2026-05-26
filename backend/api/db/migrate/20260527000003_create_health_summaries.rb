# frozen_string_literal: true

class CreateHealthSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :health_summaries do |t|
      t.references :user, null: false, foreign_key: true

      t.integer :chronotype
      t.time    :sleep_start_local
      t.time    :sleep_end_local
      t.integer :avg_sleep_duration_minutes
      t.float   :routine_stability_index
      t.integer :activity_level
      t.time    :peak_energy_start_local
      t.time    :peak_energy_end_local
      t.integer :recovery_score
      t.integer :source,         null: false
      t.date    :effective_from, null: false
      t.date    :effective_to

      t.timestamps
    end

    add_index :health_summaries, [ :user_id, :effective_from ]
  end
end
