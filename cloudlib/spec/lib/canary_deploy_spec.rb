require 'rspec'
require_relative '../../lib/cloudlib/canary_deploy'

describe Cloudlib::CanaryState do
  let(:canary_state) do
    Cloudlib::CanaryState.new(
      deploys: [], has_migrated: false, is_migrating: true,
      scheduled_scale_in_exists: false, is_scaling_new_version_to_full: false,
      all_idps_healthy: false, is_scaling_in: false, new_sha: 'def'
    )
  end

  describe '#ready_to_start_migrations?' do
    it 'is true when migrations have not been run and are not running' do
      old_deploy = Cloudlib::Deploy.new(sha: 'abc', deploy_time: Time.now)
      canary_state.deploys = [old_deploy]
      canary_state.has_migrated = false
      canary_state.is_migrating = false

      expect(canary_state.ready_to_start_migrations?).to eq true
    end
  end

  describe '#waiting_for_migrations_to_complete?' do
    it 'is true when migrations have not been run and are running' do
      old_deploy = Cloudlib::Deploy.new(sha: 'abc', deploy_time: Time.now)
      canary_state.deploys = [old_deploy]
      canary_state.has_migrated = false
      canary_state.is_migrating = true

      expect(canary_state.waiting_for_migrations_to_complete?).to eq true
    end
  end

  describe '#promotion_status' do
    let(:old_deploy) { Cloudlib::Deploy.new(sha: 'abc', deploy_time: Time.new(2021, 1, 1, 0, 0, 0)) }
    let(:new_deploy) { Cloudlib::Deploy.new(sha: 'def', deploy_time: Time.new(2021, 1, 2, 0, 0, 0)) }

    it 'raises if there are not two deploys' do
      canary_state.deploys = [old_deploy]
      expect { canary_state.promotion_status }.to raise_error(ArgumentError, 'Invalid number of deploys')
    end

    it 'returns :good when deploy metrics are good' do
      old_deploy.request_metrics = { count: 2000, five_hundred_percent: 0.01 }
      new_deploy.request_metrics = { count: 2000, five_hundred_percent: 0.0001 }
      canary_state.deploys = [old_deploy, new_deploy]
      expect(canary_state.promotion_status).to eq :good
    end

    it 'returns :bad when deploy metrics are bad' do
      old_deploy.request_metrics = { count: 2000, five_hundred_percent: 0.001 }
      new_deploy.request_metrics = { count: 2000, five_hundred_percent: 0.1 }
      canary_state.deploys = [old_deploy, new_deploy]
      expect(canary_state.promotion_status).to eq :bad
    end

    it 'returns :not_enough_data when deploy metrics are insufficient' do
      old_deploy.request_metrics = { count: 2, five_hundred_percent: 0.001 }
      new_deploy.request_metrics = { count: 2, five_hundred_percent: 0.1 }
      canary_state.deploys = [old_deploy, new_deploy]
      expect(canary_state.promotion_status).to eq :not_enough_data
    end
  end
end
