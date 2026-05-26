class CreateMatchParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :match_participants do |t|
      t.references :match, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.integer    :role,  null: false, default: 1

      t.timestamps
    end

    add_index :match_participants, [ :match_id, :user_id ], unique: true
  end
end
