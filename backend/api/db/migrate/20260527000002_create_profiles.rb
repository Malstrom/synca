class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }

      t.string  :display_name,    null: false
      t.date    :birth_date,      null: true
      t.string  :gender,          null: true
      t.text    :bio,             null: true
      t.string  :city,            null: true
      t.string  :photo_url_main,  null: true
      t.jsonb   :photo_urls,      null: false, default: []
      t.float   :trust_score,     null: false, default: 50.0
      t.boolean :spark_verified,  null: false, default: false

      t.timestamps
    end
  end
end
