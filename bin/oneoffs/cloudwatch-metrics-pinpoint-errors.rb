#!/usr/bin/env ruby
# frozen_string_literal: true

require 'aws-sdk-cloudwatch'
require 'json'
require 'yaml'

def new_cloudwatch_client
  Aws::CloudWatch::Client.new
end

def errors_for_time_window(period: 300, err_count_threshold: 50,
                           application_id:, start_time:, end_time:)

  client = new_cloudwatch_client

  queries = %w[temp_fail perm_fail throttled].map { |type|
    cw_query_for(type: type, period: period, application_id: application_id)
  }

  res = client.get_metric_data(
    metric_data_queries: queries, start_time: start_time, end_time: end_time,
    scan_by: 'TimestampAscending'
  )

  {
    'start_time' => start_time,
    'end_time' => end_time,
    'period' => period,
    'application_id' => application_id,
    'report_threshold_gte' => err_count_threshold,
    'metrics' => res.metric_data_results.map { |data|
      {
        'id' => data.id,
        'label' => data.label,
        'data' => data.timestamps.zip(data.values).find_all { |_tstamp, value|
          value >= err_count_threshold
        },
      }
    },
  }
end

def cw_query_for(type:, period: 300, stat: 'Sum', application_id:)
  sms_channel_types = {
    'temp_fail' => 'DirectSendMessageTemporaryFailure',
    'perm_fail' => 'DirectSendMessagePermanentFailure',
    'throttled' => 'DirectSendMessageThrottled',
  }
  no_channel_types = {
    'total' => 'TotalEvents',
  }

  dimensions = [
    {
      name: 'ApplicationId',
      value: application_id,
    },
  ]

  if sms_channel_types.include?(type)
    metric_name = sms_channel_types.fetch(type)
    dimensions << { name: 'Channel', value: 'SMS' }

  elsif no_channel_types.include?(type)
    metric_name = no_channel_types.fetch(type)

  else
    raise ArgumentError.new(
      "Unknown type: #{type.inspect}. Expected one of: " + \
      (sms_channel_types.keys + no_channel_types.keys).inspect
    )
  end

  {
    id: type,
    return_data: true,
    metric_stat: {
      metric: {
        namespace: 'AWS/Pinpoint',
        metric_name: metric_name,
        dimensions: dimensions,
      },
      period: period,
      stat: stat,
    },
  }
end

def usage
  STDERR.puts <<-EOM
usage: cloudwatch-metrics-pinpoint-errors.rb APPLICATION_ID START_TIME END_TIME [PERIOD]
  EOM
end

def main(args)
  if args.length < 3
    usage
    exit 1
  end

  application_id = args.fetch(0)
  start_time = args.fetch(1)
  end_time = args.fetch(2)
  period = Integer(args.fetch(3, 300))

  res = errors_for_time_window(
    period: period,
    err_count_threshold: 40,
    application_id: application_id,
    start_time: start_time,
    end_time: end_time
  )

  # puts JSON.pretty_generate(res)
  puts YAML.dump(res)
end

if $0 == __FILE__
  main(ARGV)
end
