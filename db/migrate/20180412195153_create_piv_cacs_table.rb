class CreatePivCacsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :piv_cacs do |t|
      t.string :uuid, null: false
      t.string :dn_signature, null: false

      t.index :uuid, unique: true
      t.index :dn_signature, unique: true
    end
  end
end
