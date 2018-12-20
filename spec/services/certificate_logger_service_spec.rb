require 'rails_helper'

RSpec.describe CertificateLoggerService do
  let(:service) { described_class }
  let(:certificate) { Certificate.new(x509_cert) }
  let(:ocsp_response) { OCSPResponse.new(service_request, response) }

  let(:cert_collection) do
    create_certificate_set(
      root_count: 1,
      intermediate_count: 1,
      leaf_count: 1
    )
  end

  let(:root_cert) { certificates_in_collection(cert_collection, :type, :root).first.x509_cert }
  let(:intermediate_cert) do
    certificates_in_collection(cert_collection, :type, :intermediate).first.x509_cert
  end
  let(:leaf_cert) { certificates_in_collection(cert_collection, :type, :leaf).first.x509_cert }

  let(:x509_cert) { leaf_cert }

  let(:ocsp_response_status) { false }
  let(:status) { :valid }

  let(:ocsp_responder) do
    OpenStruct.new(
      call: OpenStruct.new(revoked?: ocsp_response_status)
    )
  end

  let(:service_request) do
    service = OCSPService.new(certificate)
    service.send(:build_request)
    service
  end

  let(:request_der) { service_request.request.to_der }

  let(:response) do
    OpenSSL::OCSP::Response.new(
      create_ocsp_response(request_der, cert_collection, status)
    )
  end

  let(:certificate_store) { CertificateStore.instance }

  let(:ca_file_path) { data_file_path('certs.pem') }

  let(:ca_file_content) do
    [root_cert, intermediate_cert].map { |cert| Certificate.new(cert) }.map(&:to_pem).join("\n\n")
  end

  let(:root_cert_key_id) { Certificate.new(root_cert).key_id }
  before(:each) do
    allow(IO).to receive(:binread).with(ca_file_path).and_return(ca_file_content)
    allow(Figaro.env).to receive(:trusted_ca_root_identifiers).and_return(root_cert_key_id)
    certificate_store.clear_trusted_ca_root_identifiers
    certificate_store.add_pem_file(ca_file_path)
    allow(OCSPService).to receive(:new).and_return(service_request)
  end

  after(:each) do
    service.instance_variable_set(:@bucket, nil)
  end

  context 'with no bucket configured' do
    before(:each) do
      allow(Figaro.env).to receive(:client_cert_logger_s3_bucket_name) {}
    end

    describe '#log_certificate' do
      it 'does nothing' do
        expect(Aws::S3::Resource).to_not receive(:new)
        service.log_certificate(certificate)
      end
    end

    describe '#log_ocsp_response' do
      it 'does nothing' do
        expect(Aws::S3::Resource).to_not receive(:new)
        service.log_ocsp_response(ocsp_response)
      end
    end
  end

  context 'with a bucket configured' do
    before(:each) do
      allow(Figaro.env).to receive(:client_cert_logger_s3_bucket_name) { 'cert_logging_bucket' }
    end

    describe '#log_certificate' do
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

    describe '#log_ocsp_response' do
      it 'puts the ocsp response info in the bucket' do
        allow(Aws::S3::Resource).to receive(:new) do
          resource = double
          allow(resource).to receive(:bucket).with('cert_logging_bucket') do
            bucket = double
            allow(bucket).to receive(:object).with(ocsp_response.logging_filename) do
              object = double
              expect(object).to receive(:put).with(
                body: ocsp_response.logging_content
              ) {}
              object
            end
            bucket
          end
          resource
        end

        service.log_ocsp_response(ocsp_response)
      end
    end
  end
end
