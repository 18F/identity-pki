class CreateUnrecognizedCertificateAuthoritiesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :unrecognized_certificate_authorities do |t|
      t.string :key, null: false
      t.string :dn, null: false
      t.string :crl_http_url
      t.string :ocsp_url
      t.string :ca_issuer_url
      t.timestamps

      t.index :key, unique: true
    end
  end
end
