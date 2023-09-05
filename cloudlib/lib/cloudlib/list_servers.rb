# frozen_string_literal: true
require 'active_support/core_ext/object'

module Cloudlib
  # module containing some useful functions for slicing and dicing a server
  # listing, like ls-servers
  module ListServers

    class NoSuchHeader < Cloudlib::Error; end

    def self.log
      @log ||= Cloudlib.class_log(self, STDERR)
    end

    HEADER_FUNCTIONS = {
      'instance-id' => proc(&:instance_id),
      'image-id' => proc(&:image_id),
      'name' => proc { |i| Cloudlib::EC2.name_tag(i, allow_nil: true) || '' },
      'instance-type' => proc(&:instance_type),
      'private-ip' => proc(&:private_ip_address),
      'public-ip' => proc { |i| i.public_ip_address || '' },
      'state' => proc { |i| i.state.name },
      'launch-time' => proc { |i| i.launch_time.to_s },
      'uptime' => proc { |i| pretty_time(Time.now - i.launch_time) },
      'AZ' => proc { |i| i.placement.availability_zone },
      'sha' => proc do |i|
        (
          Cloudlib::EC2.fetch_tag(i, 'gitsha:idp', allow_nil: true) ||
          Cloudlib::EC2.fetch_tag(i, 'gitsha:app', allow_nil: true) ||
          Cloudlib::EC2.fetch_tag(i, 'gitsha:pivcac', allow_nil: true) ||
          Cloudlib::EC2.fetch_tag(i, 'gitsha:worker', allow_nil: true) ||
         '')[0..8]
      end,
    }.freeze

    HEADER_ALIASES = {
      'id' => 'instance-id',
      'availability-zone' => 'AZ',
      'az' => 'AZ',
    }.freeze

    DEFAULT_HEADERS = %w[
      instance-id
      image-id
      name
      instance-type
      AZ
      state
      launch-time
      uptime
    ].freeze

    OPTIONAL_HEADERS = %w[
      sha
    ].freeze

    LONG_HEADERS = %w[
      instance-id
      image-id
      name
      instance-type
      AZ
      private-ip
      public-ip
      state
      launch-time
      uptime
    ].freeze

    def self.data_for_instances(instances, headers: nil, long_headers: false)
      unless headers
        if long_headers
          headers = LONG_HEADERS + OPTIONAL_HEADERS
        else
          headers = DEFAULT_HEADERS + OPTIONAL_HEADERS
        end
      end
      headers = headers.dup

      # sort instances by name tag, then launch time
      instances = instances.sort_by { |i|
        [
          Cloudlib::EC2.name_tag(i, allow_nil: true) || '',
          i.launch_time,
        ]
      }

      data = instances.map { |i|
        headers.map { |header|
          [header, get_header_function(header).call(i)]
        }.to_h
      }

      OPTIONAL_HEADERS.map do |header|
        value_exists = data.any? { |x| x[header].present? }

        unless value_exists
          headers.delete(header)

          data.each do |x|
            x.delete(header)
          end
        end
      end

      return {
        header: headers,
        rows: data.map(&:values),
      }
    end

    def self.pretty_time(total_seconds)
      total_hrs, secs = total_seconds.divmod(3600)
      days, hrs = total_hrs.divmod(24)
      mins = format('%02d', secs / 60)

      if days > 0
        "#{days}d #{hrs}h#{mins}m"
      else
        "#{hrs}h#{mins}m"
      end
    end

    def self.get_header_function(header_name)
      if HEADER_ALIASES.include?(header_name)
        return HEADER_FUNCTIONS.fetch(HEADER_ALIASES.fetch(header_name))
      end

      HEADER_FUNCTIONS.fetch(header_name)
    rescue KeyError
      raise NoSuchHeader.new(
        "Could not find listservers header named #{header_name.inspect}"
      )
    end
  end
end
