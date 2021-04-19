require_relative 'boot'

require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'identity/logging/railtie'
require_relative '../lib/identity_config'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module IdentityPki
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1


    configuration = YAML.safe_load(File.read(File.join(Rails.root, 'config', 'application.yml')))
    root_config = configuration.except('development', 'production', 'test')
    environment_config = configuration[Rails.env]
    merged_config = root_config.merge(environment_config)
    merged_config.symbolize_keys!

    IdentityConfig.build_store(merged_config)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
