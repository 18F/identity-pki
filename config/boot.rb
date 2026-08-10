ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
# Speed up boot time by caching expensive operations.
require 'bootsnap/setup' if ENV['ENABLE_BOOTSNAP'] != 'false'
