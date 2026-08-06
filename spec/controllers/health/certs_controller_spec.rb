require 'rails_helper'

RSpec.describe Health::CertsController do
  describe '#index' do
    subject(:action) { get :index, params: { deadline: deadline } }
    let(:deadline) { nil }
    let(:health_checker) { HealthChecker.new(certificates_store: certificates_store) }

    it 'renders a status as JSON' do
      action

      expect(response.media_type).to eq('application/json')
      expect(JSON.parse(response.body, symbolize_names: true)).to include(:healthy)
    end

    context 'certs health' do
      before do
        allow(controller).to receive(:health_checker).and_return(health_checker)
      end

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

      context 'with expiring certs' do
        let(:certificates_store) { [expiring_cert] }

        it 'returns a 503' do
          action

          expect(response.status).to eq(503)

          body = JSON.parse(response.body, symbolize_names: true)
          expect(body).to include(healthy: false)
          expect(body[:info][:expiring].first[:key_id]).to eq(expiring_cert.key_id)
        end
      end

      context 'with no expiring certs' do
        let(:certificates_store) { [] }

        it 'returns a 200' do
          action

          expect(response.status).to eq(200)
          expect(JSON.parse(response.body, symbolize_names: true)).to include(healthy: true)
        end

        context 'with a deadline param as a timestamp' do
          let(:deadline) { '2020-01-01' }

          it 'checks certs with that deadline' do
            expect(health_checker).to receive(:check_certs).
              with(deadline: Time.zone.parse(deadline)).
              and_call_original

            action
          end
        end

        context 'with a deadline param as an interval' do
          let(:deadline) { '7d' }

          it 'checks certs with that deadline' do
            expect(health_checker).to receive(:check_certs).and_wrap_original do |impl, args|
              expect(args[:deadline].to_i).to be_within(1).of(7.days.from_now.to_i)

              impl.call(**args)
            end

            action
          end
        end
      end
    end
  end
end
