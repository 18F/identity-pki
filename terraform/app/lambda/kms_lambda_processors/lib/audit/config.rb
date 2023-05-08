# frozen_string_literal: true

require 'json'

module IdentityAudit
  # Class to handle loading config from config.json
  class Config
    def config_dir
      File.absolute_path(File.dirname(__FILE__) + '/../..')
    end

    def config_file_path
      override = config_dir + '/config.json'
      if File.exist?(override)
        override
      else
        config_dir + '/config.json.default'
      end
    end

    def data
      @data ||= JSON.parse(File.read(config_file_path))
    end
  end
end
