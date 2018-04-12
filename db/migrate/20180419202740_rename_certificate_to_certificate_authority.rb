class RenameCertificateToCertificateAuthority < ActiveRecord::Migration[5.1]
  def self.up
    rename_table :certificates, :certificate_authorities
    rename_index :certificate_revocations, 'index_certificate_revocations_on_certificate_id_and_serial', 'index_certificate_revocations_on_cert_auth_id_and_serial'
    rename_column :certificate_revocations, :certificate_id, :certificate_authority_id
  end

  def self.down
    rename_table :certificate_authorities, :certificates
    rename_index :certificate_revocations, 'index_certificate_revocations_on_cert_auth_id_and_serial', 'index_certificate_revocations_on_certificate_id_and_serial'
    rename_column :certificate_revocations, :certificate_authority_id, :certificate_id
  end
end
