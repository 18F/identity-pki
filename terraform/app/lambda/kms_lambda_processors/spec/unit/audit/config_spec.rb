RSpec.describe IdentityAudit::Config do
  describe '#config_file_path' do
    it 'defaults to config.json.default' do
      instance = IdentityAudit::Config.new
      allow(instance).to receive(:config_dir).and_return('/nonexistent')

      expect(instance.config_file_path).to eq('/nonexistent/config.json.default')
    end
  end

  describe '#data' do
    it 'parses JSON' do
      instance = IdentityAudit::Config.new
      allow(instance).to receive(:config_file_path).and_return('stub-config-path')
      allow(File).to receive(:read).with('stub-config-path').and_return('{"foo": 1, "bar": 2}')
      expect(instance.data).to eq({'foo' => 1, 'bar' => 2})
    end

    it 'has expected keys in config' do
      data = IdentityAudit::Config.new.data
      expect(data).to include('identity-audit')
      keys = %w[team_yml_github_repo team_yml_relative_path secret_id_for_github_access_token]
      expect(data.fetch('identity-audit')).to include(*keys)
    end
  end
end
