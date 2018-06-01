require 'csv'

namespace :crls do
  desc 'update CRL entries in the database'
  task update: :environment do
    # The timeout value isn't significant as long as it is large since we're doing
    # bulk inserts that can take a while to execute.
    ActiveRecord::Base.connection.execute('set statement_timeout to 1000000')
    CertificateAuthority.
      with_crl_http_url.
      find_each do |authority|
      begin
        Rails.logger.info "Updating #{authority.key} #{authority.dn} <#{authority.crl_http_url}>"
        authority.update_revocations
      rescue StandardError => e
        Rails.logger.warn "  Unable to update CRL from <#{authority.crl_http_url}>: #{e}"
      end
    end
  end

  desc 'dump CRL information from database into a CSV file'
  task :dump, [:file] => :environment do |_task, args|
    file = args[:file]
    csv = if file.blank? || file == '-'
            CSV($stdout)
          else
            CSV.open(file, 'wb')
          end

    CertificateAuthority.find_each do |authority|
      csv << [
        authority.key,
        authority.valid_not_before,
        authority.valid_not_after,
        authority.dn,
        authority.crl_http_url,
      ]
    end
  end

  desc 'load CRL information into database from a CSV file'
  task :load, [:file] => :environment do |_task, args|
    file = args[:file]
    csv = if file.blank? || file == '-'
            CSV($stdin)
          else
            CSV.open(file, 'rb')
          end
    csv.each do |(key, valid_not_before, valid_not_after, dn, crl_http_url, *_rest)|
      record = CertificateAuthority.create_with(
        valid_not_before: valid_not_before,
        valid_not_after: valid_not_after,
        crl_http_url: crl_http_url
      ).find_or_create_by(key: key, dn: dn)

      if crl_http_url.present? && crl_http_url != record.crl_http_url
        record.crl_http_url = crl_http_url
        record.save
      end
    end
  end
end
