require 'rails_helper'

RSpec.describe CertificateLoggerService do
  let(:service) { described_class }
  let(:certificate) { Certificate.new(x509_cert) }

  let(:cert_collection) do
    create_certificate_set(
      root_count: 1,
      intermediate_count: 1,
      leaf_count: 1
    )
  end

  let(:root_cert) { cert_collection.first.first }
  let(:intermediate_cert) { cert_collection[1].first }
  let(:leaf_cert) { cert_collection.last.first }

  let(:x509_cert) { leaf_cert }

  after(:each) do
    service.instance_variable_set(:@bucket, nil)
  end

  describe '#log_certificate' do
    context 'with no bucket configured' do
      before(:each) do
        allow(Figaro.env).to receive(:client_cert_logger_s3_bucket_name) {}
      end

      it 'does nothing' do
        expect(Aws::S3::Resource).to_not receive(:new)
        service.log_certificate(certificate)
      end
    end

    context 'with a bucket configured' do
      before(:each) do
        allow(Figaro.env).to receive(:client_cert_logger_s3_bucket_name) { 'cert_logging_bucket' }
      end

      it 'puts the certificate info in the bucket' do
        allow(Aws::S3::Resource).to receive(:new) do
          resource = double
          allow(resource).to receive(:bucket).with('cert_logging_bucket') do
            bucket = double
            allow(bucket).to receive(:object).with(certificate.logging_filename) do
              object = double
              expect(object).to receive(:put).with(
                body: certificate.logging_content
              ) {}
              object
            end
            bucket
          end
          resource
        end

        service.log_certificate(certificate)
      end
    end
  end
end
