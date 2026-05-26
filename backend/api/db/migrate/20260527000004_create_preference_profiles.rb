class CreatePreferenceProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :preference_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.jsonb   :visual_embedding, null: true
      t.integer :travel_style,     null: true  # enum: homebody, balanced, explorer
      t.jsonb   :music_profile,    null: true

      t.timestamps
    end
  end
end
