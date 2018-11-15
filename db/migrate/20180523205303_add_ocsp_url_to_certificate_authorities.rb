class AddOcspUrlToCertificateAuthorities < ActiveRecord::Migration[5.2]
  def change
    add_column :certificate_authorities, :ocsp_http_url, :string
  end
end
