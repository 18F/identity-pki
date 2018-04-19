class AddCertificatesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :certificates do |t|
      t.string :key, null: false
      t.string :dn, null: false
      t.string :crl_http_url
      t.datetime :valid_not_before, null: false
      t.datetime :valid_not_after, null: false
      t.timestamps

      t.index :key, unique: true
    end
  end
end
