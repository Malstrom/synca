class CreateSparkSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :spark_sessions do |t|
      # Two FK on users: use explicit column names instead of t.references
      t.bigint :initiator_id, null: false
      t.bigint :partner_id,   null: true

      t.integer :status,       null: false, default: 0  # enum: pending, active, completed, expired
      t.string  :session_code, null: false
      t.string  :qr_token,     null: false
      t.float   :location_lat, null: true
      t.float   :location_lng, null: true
      t.datetime :started_at,  null: true
      t.datetime :completed_at, null: true
      t.jsonb   :initiator_answers, null: true
      t.jsonb   :partner_answers,   null: true
      t.float   :compatibility_score,          null: true
      t.boolean :reward_issued_initiator,       null: false, default: false
      t.boolean :reward_issued_partner,         null: false, default: false

      t.timestamps
    end

    add_foreign_key :spark_sessions, :users, column: :initiator_id
    add_foreign_key :spark_sessions, :users, column: :partner_id

    add_index :spark_sessions, :initiator_id
    add_index :spark_sessions, :partner_id
    add_index :spark_sessions, :session_code, unique: true
    add_index :spark_sessions, :qr_token,     unique: true
    add_index :spark_sessions, :status
  end
end
