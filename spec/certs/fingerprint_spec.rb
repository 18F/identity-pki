require 'rails_helper'

RSpec.describe 'Root Certificates' do
  let(:config_dir) { Rails.root.join('config') }

  fpki_g2 = 'c=US, O=U.S. Government, OU=FPKI, CN=Federal Common Policy CA G2.pem'

  describe fpki_g2 do
    it 'FPKI fingerprint matches https://fpki.idmanagement.gov/common/obtain-and-verify/' do
      path = File.join(config_dir, 'certs', fpki_g2)
      expect(File.exist?(path)).to eq(true)

      cert = OpenSSL::X509::Certificate.new File.read path
      expect(OpenSSL::Digest::SHA256.new(cert.to_der).to_s).to eq(
        '5f9aecc24616b2191372600dd80f6dd320c8ca5a0ceb7f09c985ebf0696934fc'
      )
    end
  end
end
