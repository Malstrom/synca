# frozen_string_literal: true

class AddMagicLinkToUsers < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_column :users, :magic_link_token, :string, null: true
    add_column :users, :magic_link_sent_at, :datetime, null: true

    add_index :users, :magic_link_token, unique: true, algorithm: :concurrently
  end
end
