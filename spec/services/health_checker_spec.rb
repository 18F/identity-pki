require 'rails_helper'

RSpec.describe HealthChecker do
  describe '#check_certs' do
    subject(:health_checker) { HealthChecker.new(certificates_store: certificates_store) }
    let(:deadline) { 30.days.from_now }

    let(:expiring_cert) do
      instance_double(
        'Certificate',
        expired?: true,
        not_after: 15.days.from_now,
        subject: OpenSSL::X509::Name.new([%w[CN cert1], %w[OU example]]),
        issuer: OpenSSL::X509::Name.new([%w[CN issuer1], %w[OU example]]),
        key_id: 'ab:cd:ef:gh:jk'
      )
    end

    let(:not_expiring_cert) do
      instance_double(
        'Certificate',
        expired?: false,
        not_after: 45.days.from_now,
        subject: OpenSSL::X509::Name.new([%w[CN cert2], %w[OU example]]),
        issuer: OpenSSL::X509::Name.new([%w[CN issuer2], %w[OU example]]),
        key_id: 'lm:no:pq:rs:tu'
      )
    end

    context 'with certs that expire before the deadline' do
      let(:certificates_store) { [expiring_cert, not_expiring_cert] }

      it 'returns an unhealthy result with the expiring certs' do
        result = health_checker.check_certs(deadline: deadline)

        expect(result).to_not be_healthy
        expect(result.info).to eq(
          deadline: deadline,
          expiring: [
            {
              expiration: expiring_cert.not_after,
              subject: '/CN=cert1/OU=example',
              issuer: '/CN=issuer1/OU=example',
              key_id: expiring_cert.key_id,
            },
          ]
        )
      end
    end

    context 'with no certs that expire before the deadline' do
      let(:certificates_store) { [not_expiring_cert] }

      it 'returns a healthy result with no certs' do
        result = health_checker.check_certs(deadline: deadline)

        expect(result).to be_healthy
        expect(result.info).to eq(deadline: deadline, expiring: [])
      end
    end
  end
end
