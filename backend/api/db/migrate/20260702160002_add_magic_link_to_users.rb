# frozen_string_literal: true

class AddMagicLinkToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :magic_link_token, :string, index: true
    add_column :users, :magic_link_sent_at, :datetime
  end
end