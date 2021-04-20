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

    configuration = Identity::Hostdata::ConfigReader.new.read_configuration(
      write_copy_to: Rails.root.join('tmp/application.yml')
    )
    IdentityConfig.build_store(configuration)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
