#
# Copyright 2015-2016, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/mixin/shell_out'

require 'poise_ruby/ruby_providers/base'


module PoiseRuby
  module RubyBuild
    # Inversion provider for `ruby_runtime` to install via ruby-build.
    #
    # @since 1.0.0
    # @provides ruby_build
    class Provider < PoiseRuby::RubyProviders::Base
      include Chef::Mixin::ShellOut
      provides(:ruby_build)

      # Add default options for ruby-build.
      #
      # @param node [Chef::Node] Node to load from.
      # @param resource [Chef::Resource] Resource to load from.
      # @return [Hash]
      def self.default_inversion_options(node, resource)
        super.merge({
          install_doc: false,
          install_repo: 'https://github.com/sstephenson/ruby-build.git',
          install_rev: 'master',
          prefix: '/opt/ruby_build',
        })
      end

      # Path to the compiled Ruby binary.
      #
      # @return [String]
      def ruby_binary
        ::File.join(options['prefix'], 'builds', new_resource.name, 'bin', 'ruby')
      end

      # Find the full definition name to use with ruby-build. This is based on
      # prefix matching from the `ruby-build --definitions` output. Only
      # public because sigh scoping.
      #
      # @!visibility private
      # @return [String]
      def ruby_definition
        @ruby_definition ||= begin
          cmd = shell_out!([::File.join(options['prefix'], 'install', options['install_rev'], 'bin', 'ruby-build'), '--definitions'])
          version_prefix = options['version']
          # Default for '', look for MRI 2.x.
          version_prefix = '2' if version_prefix == ''
          # Find the last line that starts with the target version.
          cmd.stdout.split(/\n/).reverse.find {|line| line.start_with?(version_prefix) } || options['version']
        end
      end

      private

      # Path to the version record file. Should contain the actual version of
      # Ruby installed in this folder.
      #
      # @return [String]
      def version_file
        ::File.join(options['prefix'], 'builds', new_resource.name, 'VERSION')
      end

      # Installs ruby-build and then uses that to install Ruby.
      #
      # @return [void]
      def install_ruby
        # We assume that if the version_file exists, ruby-build is already
        # installed. Calling #ruby_definition will shell out to ruby-build.
        if ::File.exists?(version_file) && IO.read(version_file) == ruby_definition
          # All set, bail out.
          return
        end

        converge_by("Installing Ruby #{options['version'].empty? ? new_resource.name : options['version']} via ruby-build") do
          notifying_block do
            create_prefix_directory
            create_install_directory
            create_builds_directory
            install_ruby_build
            install_dependencies
            # Possible failed install or a version change. Wipe the existing build.
            # If we weren't going to rebuild, we would have bailed out already.
            uninstall_ruby
          end
          # Second converge has ruby-build installed so using #ruby_definition
          # is safe.
          notifying_block do
            build_ruby
            create_version_file
          end
        end
      end

      # Create the base prefix directory.
      #
      # @return [Chef::Resource::Directory]
      def create_prefix_directory
        directory options['prefix'] do
          owner 'root'
          group 'root'
          mode '755'
        end
      end

      # Create the directory to hold ruby-build installations.
      #
      # @return [Chef::Resource::Directory]
      def create_install_directory
        directory ::File.join(options['prefix'], 'install') do
          owner 'root'
          group 'root'
          mode '755'
        end
      end

      # Create the directory to hold compiled rubies.
      #
      # @return [Chef::Resource::Directory]
      def create_builds_directory
        directory ::File.join(options['prefix'], 'builds') do
          owner 'root'
          group 'root'
          mode '755'
        end
      end

      # Clone ruby-build from GitHub or a similar git server. Will also install
      # git via the `git` cookbook unless `no_dependencies` is set.
      #
      # @return [Chef::Resource::Git]
      def install_ruby_build
        include_recipe 'git' unless options['no_dependencies']
        git ::File.join(options['prefix'], 'install', options['install_rev']) do
          repository options['install_repo']
          revision options['install_rev']
          user 'root'
        end
      end

      # Install dependency packages needed to compile Ruby. A no-op if
      # `no_dependencies` is set.
      #
      # @return [Chef::Resource::Package]
      def install_dependencies
        return if options['no_dependencies']
        include_recipe 'build-essential'
        unless options['version'].start_with?('jruby')
          pkgs = node.value_for_platform_family(
            debian: %w{libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev libxml2-dev libxslt1-dev},
            rhel: %w{tar bzip2 readline-devel zlib-devel libffi-devel openssl-devel libxml2-devel libxslt-devel},
            suse: %w{zlib-devel libffi-devel sqlite3-devel libxml2-devel libxslt-devel},
          )
          package pkgs if pkgs
        end
      end


      # Compile Ruby using ruby-build.
      #
      # @return [Chef::Resource::Execute]
      def build_ruby
        # Figure out the argument to disable docs
        disable_docs = if options['install_doc']
          nil
        elsif options['version'].start_with?('rbx')
          nil # Doesn't support?
        elsif options['version'].start_with?('ree')
          '--no-dev-docs'
        else
          '--disable-install-doc'
        end

        ENV['TMPDIR'] = options['tmp_dir'] || Chef::Config[:file_cache_path]
        execute 'ruby-build install' do
          command [::File.join(options['prefix'], 'install', options['install_rev'], 'bin', 'ruby-build'), ruby_definition, ::File.join(options['prefix'], 'builds', new_resource.name)]
          user 'root'
          environment 'RUBY_CONFIGURE_OPTS' => disable_docs if disable_docs
        end
      end

      # Write out the concrete version to the VERSION file.
      #
      # @return [Chef::Resource::File]
      def create_version_file
        file version_file do
          owner 'root'
          group 'root'
          mode '644'
          content ruby_definition
        end
      end

      # Delete the compiled Ruby, but leave ruby-build installed as it may be
      # shared by other resources.
      #
      # @return [Chef::Resource::Directory]
      def uninstall_ruby
        directory ::File.join(options['prefix'], 'builds', new_resource.name) do
          action :delete
        end
      end
    end
  end
end
