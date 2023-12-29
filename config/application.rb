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
    config.load_defaults 7.0

    Identity::Hostdata.load_config!(
      app_root: Rails.root,
      rails_env: Rails.env,
      write_copy_to: nil,
      &IdentityConfig::CONFIG_BUILDER
    )

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
