class CreateSparkRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :spark_rewards do |t|
      t.references :user,          null: false, foreign_key: true
      t.references :spark_session, null: false, foreign_key: true

      t.integer  :reward_type, null: false  # enum: premium_week, match_credit, boost
      t.integer  :status,      null: false, default: 0  # enum: pending, redeemed, expired
      t.datetime :valid_until, null: false

      t.timestamps
    end

    add_index :spark_rewards, [:user_id, :status]
  end
end
