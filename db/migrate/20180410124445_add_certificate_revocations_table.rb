class AddCertificateRevocationsTable < ActiveRecord::Migration[5.1]
  def change
    create_table :certificate_revocations do |t|
      t.bigint :certificate_id, null: false
      t.string :serial, null: false
      t.timestamps

      t.foreign_key :certificates

      t.index [:certificate_id, :serial], unique: true
    end
  end
end
