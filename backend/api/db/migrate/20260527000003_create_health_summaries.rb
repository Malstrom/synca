class CreateHealthSummaries < ActiveRecord::Migration[8.0]
  def change
    create_table :health_summaries do |t|
      t.references :user, null: false, foreign_key: true

      t.integer :chronotype,                  null: false  # enum: early_bird, intermediate, night_owl
      t.time    :sleep_start_local,           null: true
      t.time    :sleep_end_local,             null: true
      t.integer :avg_sleep_duration_minutes,  null: true
      t.float   :routine_stability_index,     null: true   # 0.0 - 1.0
      t.integer :activity_level,              null: true   # enum: low, medium, high
      t.time    :peak_energy_start_local,     null: true
      t.time    :peak_energy_end_local,       null: true
      t.integer :recovery_score,              null: true   # enum: low, medium, high
      t.integer :source,                      null: false  # enum: apple_health, health_connect
      t.date    :effective_from,              null: false
      t.date    :effective_to,               null: true

      t.timestamps
    end

    add_index :health_summaries, [:user_id, :effective_from]
  end
end
