class AddTestFieldToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :test_field, :string, null: true
  end
end
