class AddAccountTypeToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :account_type, :integer, null: false, default: 0
    add_index  :users, :account_type
  end
end
