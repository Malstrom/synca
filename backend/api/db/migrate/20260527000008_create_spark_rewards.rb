# frozen_string_literal: true

class CreateSparkRewards < ActiveRecord::Migration[8.0]
  def change
    create_table :spark_rewards do |t|
      t.references :user,  null: false, foreign_key: true
      t.references :spark, null: false, foreign_key: true
      t.integer    :reward_type, null: false
      t.integer    :status,      null: false, default: 0
      t.datetime   :valid_until

      t.timestamps
    end

    add_index :spark_rewards, [ :user_id, :status ]
    add_index :spark_rewards, [ :user_id, :spark_id ], unique: true
  end
end
