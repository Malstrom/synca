# frozen_string_literal: true

class CreateMatches < ActiveRecord::Migration[8.0]
  def change
    create_table :matches do |t|
      t.float    :compatibility_score, null: false
      t.integer  :status,              null: false, default: 0  # enum: proposed, accepted, rejected
      t.datetime :accepted_at,         null: true
      t.datetime :rejected_at,         null: true

      t.timestamps
    end
  end
end
