# frozen_string_literal: true

# create_spark_rewards used t.references :spark_session which generated:
#   - column spark_session_id
#   - a FK pointing to spark_sessions (table that does not exist; real table is :sparks)
#
# This migration corrects both issues.
class FixSparkRewardsFk < ActiveRecord::Migration[8.0]
  def change
    # 1. Remove the broken FK (references a non-existent table)
    remove_foreign_key :spark_rewards, column: :spark_session_id

    # 2. Rename the column
    rename_column :spark_rewards, :spark_session_id, :spark_id

    # 3. Add the correct FK
    add_foreign_key :spark_rewards, :sparks, column: :spark_id

    # 4. Update the index to reflect the new column name
    remove_index :spark_rewards, name: "index_spark_rewards_on_spark_session_id" if index_exists?(:spark_rewards, :spark_session_id)
    add_index    :spark_rewards, :spark_id unless index_exists?(:spark_rewards, :spark_id)
  end
end
