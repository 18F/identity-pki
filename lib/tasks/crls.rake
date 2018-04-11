namespace :crls do
  desc 'update CRL entries in the database'
  task update: :environment do
    Certificate.with_crl_http_url.includes(:certificate_revocations).find_each do |certificate|
      begin
        certificate.update_revocations
      rescue StandardError => e
        puts "Unable to update CRL from <#{certificate.crl_http_url}>: #{e}"
      end
    end
  end
end
