class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string  :email
      t.string  :phone
      t.integer :auth_provider, null: false, default: 0
      t.string  :provider_uid
      t.string  :password_digest

      t.timestamps
    end

    add_index :users, :email, unique: true, where: "email IS NOT NULL"
    add_index :users, :phone, unique: true, where: "phone IS NOT NULL"
    add_index :users, [ :auth_provider, :provider_uid ], unique: true, where: "provider_uid IS NOT NULL"
  end
end
