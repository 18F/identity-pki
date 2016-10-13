require 'pp'
require 'yaml'
require 'open-uri'
require 'erb'
require 'colorize'

class YamlKeyChecker
  IDP_APPLICATION_YML = 'https://raw.githubusercontent.com/18F/identity-idp' \
    '/master/config/application.yml.example'.freeze
  
  APPLICATION_YML_TEMPLATE = './kitchen/cookbooks/login_dot_gov/templates/' \
    'default/application.yml.erb'.freeze
  DEFAULTS_TEMPLATE = './kitchen/cookbooks/login_dot_gov/attributes/default.rb'

  def initialize
    @missing_keys = []

    @idp_yml_file = IDP_APPLICATION_YML
    @app_template = APPLICATION_YML_TEMPLATE
    @defaults_template = DEFAULTS_TEMPLATE
  end

  def validate!
    validate_application_yml_template
    validate_default_values

    raise MissingKeysException.new(@missing_keys) unless @missing_keys.empty?
    puts "Success! No missing keys found!".green
    true
  end

  private

  def validate_application_yml_template
    idp_yml = load_yml_from_url(@idp_yml_file)
    # check for keys outside of Rails.env
    idp_yml.each do |key,val|
      next if key.match(/production|development|test/)
      @missing_keys << { key: key,
                         file: @app_template } unless template_yml['production'][key]
    end
    # check 'production' for key
    idp_yml['production'].each do |key,val|
      @missing_keys << { key: key,
                         file: @app_template } unless template_yml['production'][key]
    end
  end

  def validate_default_values
    default = Hash.new
    default['login_dot_gov'] = Hash.new
    eval(File.open(@defaults_template).read)

    idp_yml = load_yml_from_url(@idp_yml_file)
    # check for keys outside of Rails.env
    idp_yml.each do |key,val|
      next if key.match(/production|development|test/)
      @missing_keys << { key: key,
                         file: @defaults_template } unless default['login_dot_gov'][key]
    end

    # check 'production' group for key
    idp_yml['production'].each do |key,val|
      @missing_keys << { key: key,
                         file: @defaults_template } unless default['login_dot_gov'][key]
    end
  end

  def load_yml_from_url(url)
    yaml_content = open(url){|f| f.read}
    YAML::load(yaml_content)
  end

  def load_file(filename)
    File.open(filename).read
  end

  def template_yml
    @_yml ||= YAML.load(ERB.new(load_file(@app_template)).result)
  end
end

class MissingKeysException < StandardError
  def initialize(keys)
    @keys = keys
    puts 'Missing keys found!'.red
    pp @keys
    
    puts "\n"
    puts 'Check the following files for inclusion of all keys:'
    puts '  - ./kitchen/cookbooks/login_dot_gov/attributes/default.rb'
    puts '  - ./kitchen/cookbooks/login_dot_gov/resources/idp_configs.rb'
    puts '  - ./kitchen/cookbooks/login_dot_gov/templates/default/application.yml.erb'
  end
end
