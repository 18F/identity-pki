#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optionparser'

require 'aws-sdk-cloudwatchlogs'
require 'aws-sdk-s3'

require_relative '../../cloudlib/lib/cloudlib'

# Download event logs for the specified time period from CloudWatch Logs and
# upload them to S3.
class EventMover
  attr_reader :log_bucket_name
  attr_reader :log_client
  attr_reader :log_group_name
  attr_reader :s3_client

  def initialize(log_group_name:, log_bucket_name:)
    @log_client = Aws::CloudWatchLogs::Client.new
    @log_group_name = log_group_name
    @log_bucket_name = log_bucket_name
    @s3_client = s3_client_create

    log.info("EventMover log_group_name: #{log_group_name}," \
             " log_bucket_name: #{log_bucket_name}")
  end

  def log
    Cloudlib.cli_log
  end

  def list_log_streams(start_time: nil, end_time: nil)
    log_streams = []
    log_client.describe_log_streams(
      order_by: 'LastEventTime', log_group_name: log_group_name
    ).each do |resp|
      log_streams.concat(resp.log_streams)
    end

    # if start time is provided, find all streams that have at least one event
    # after start_time
    if start_time
      log_streams.select! { |s|
        parse_timestamp_ms(s.last_event_timestamp) >= start_time
      }
    end

    # if end time is provided, find all streams that have at least one event
    # before end_time
    if end_time
      log_streams.select! { |s|
        parse_timestamp_ms(s.first_event_timestamp) <= end_time
      }
    end

    log_streams
  end

  def each_log_event_in_stream(log_stream_name, start_time: nil, end_time: nil)
    unless block_given?
      return to_enum(:each_log_event_in_stream, log_stream_name, start_time:
                     start_time, end_time: end_time)
    end
    log_client.get_log_events(
      log_group_name: log_group_name,
      log_stream_name: log_stream_name,
      start_from_head: true,
      start_time: (start_time ? time_to_stamp_ms(start_time) : nil),
      end_time: (end_time ? time_to_stamp_ms(end_time) : nil)
    ).each do |resp|
      resp.events.each do |event|
        yield event
      end
    end
  end

  # Add logstash-like timestamp and hostname to the input log event.
  def render_event_as_syslog(event, log_stream_name)
    time_string = parse_timestamp_ms(event.timestamp).iso8601(3)

    [time_string, log_stream_name, event.message].join(' ') + "\n"
  end

  # @param [Integer] split_bytes Maximum size of output text files
  #
  # @return [Array<String>] A list of locally downloaded filenames
  def download_log_stream(log_stream_name:, start_time: nil, end_time: nil,
                          out_dir: '.', split_bytes: nil)

    basedir = File.join(out_dir, log_stream_name)
    log.info("Downloading log stream #{log_stream_name.inspect} to " +
             basedir.inspect)

    if start_time || end_time
      log.info("Download filtering start: #{start_time.inspect}, " \
               "end: #{end_time.inspect}")
    end

    Dir.mkdir(basedir)

    event_count = 0

    next_file_index = 0
    filenames = []

    cur_file = nil
    cur_file_bytes = nil

    # iterate over all log events in the stream for the given time window
    each_log_event_in_stream(log_stream_name,
                             start_time: start_time,
                             end_time: end_time) do |event|

      # transform the event into a logstash/syslog like format
      output_data = render_event_as_syslog(event, log_stream_name)

      # open a new file if no file yet or if we would exceed the split size
      if cur_file.nil? || \
         (split_bytes && (cur_file_bytes + output_data.bytesize > split_bytes))

        if split_bytes
          f_base = log_stream_name + format('_part.%04d.txt', next_file_index)
        else
          f_base = log_stream_name + '.txt'
        end
        filename = File.join(basedir, f_base)

        log.info("Creating new output file #{filename.inspect}")
        cur_file = File.open(filename, File::WRONLY | File::CREAT | File::EXCL)
        filenames << filename
        cur_file_bytes = 0
        next_file_index += 1
      end

      # write the event to the file
      cur_file.write(output_data)
      cur_file_bytes += output_data.bytesize
      event_count += 1
    end

    log.info("Wrote #{event_count} events to #{filenames.length} files")

    filenames
  end

  def parse_timestamp_ms(ms_timestamp)
    Time.at(ms_timestamp / 1000.0).utc
  end

  def time_to_stamp_ms(time)
    unless time.is_a?(Time)
      raise ArgumentError.new("Unexpected Time object: #{time.inspect}")
    end
    (time.to_f * 1000).round
  end

  # @param [Integer] split_bytes Maximum size of output text files that are
  #   uploaded to S3
  def download_and_reupload_time_window(start_time: nil, end_time: nil,
                                        out_dir: '.', skip_streams: nil,
                                        s3_key_prefix: nil, skip_delete: false,
                                        dry_run: false, split_bytes: nil)
    if s3_key_prefix && !s3_key_prefix.end_with?('/')
      raise ArgumentError.new('Expected S3 prefix to end with /')
    end
    if start_time || end_time
      log.info('Downloading and reuploading logs between ' +
               "#{start_time || 'forever'} and #{end_time || 'forever'}")
    else
      log.info('Downloading and reuploading logs from all time')
    end

    log_streams = list_log_streams(start_time: start_time, end_time: end_time)
    streams_count = log_streams.count

    log.info("Found #{streams_count} log streams:")

    # make sure we have a deterministic order
    log_streams.sort_by!(&:log_stream_name)

    log_streams.each do |stream|
      log.info('  - ' + stream.log_stream_name)
    end

    log_streams.each_with_index do |stream, i|
      stream_name = stream.log_stream_name
      if skip_streams&.include?(stream_name)
        log.info("Skipping #{stream_name.inspect}, due to skip list")
        next
      end

      log.info("(#{i + 1}/#{streams_count}) Processing stream #{stream_name}")
      log.info("This stream stores #{stream.stored_bytes} bytes in total")

      filenames = download_log_stream(
        log_stream_name: stream_name, start_time: start_time,
        end_time: end_time, out_dir: out_dir, split_bytes: split_bytes
      )

      filenames_len = filenames.length

      filenames.each_with_index do |filename, f_n|
        log.info("Uploading file #{f_n + 1}/#{filenames_len} to S3")
        upload_log_stream_to_s3(filename: filename, dry_run: dry_run,
                                s3_key_prefix: s3_key_prefix,
                                stream_name: stream_name)
      end

      filenames.each do
        delete_local_file(filename) unless skip_delete
      end
    end

    log.info("Finished processing all #{streams_count} log streams")
  end

  def delete_local_file(filename)
    log.info("rm #{filename.inspect}")
    File.unlink(filename)
  end

  def s3_client_create
    Aws::S3::Client.new
  end

  def default_s3_upload_prefix
    "imported_from_cloudwatch_logs/#{File.basename(log_group_name)}/"
  end

  def upload_log_stream_to_s3(filename:, s3_key_prefix: nil, stream_name: nil,
                              s3_key_suffix: '', dry_run: false)
    s3_key_prefix ||= default_s3_upload_prefix
    s3_key_prefix += stream_name + '/' if stream_name

    s3_key = s3_key_prefix + File.basename(filename) + s3_key_suffix
    s3_put_object(filename: filename, s3_key: s3_key, dry_run: dry_run)
  end

  def s3_put_object(filename:, s3_key:, dry_run: false)
    s3_url = "s3://#{log_bucket_name}/#{s3_key}"

    if dry_run
      log.info("Skipping upload due to dry run. Would upload to: #{s3_url}")
      return false
    end

    log.info("Uploading #{filename.inspect} to #{s3_url}")

    File.open(filename, 'rb') do |file|
      s3_client.put_object(bucket: log_bucket_name, key: s3_key, body: file)
    end

    log.info('Upload completed')
  end
end

def main
  # options = {}
  reupload_options = {}

  # rubocop:disable Metrics/BlockLength
  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
usage: #{File.basename($0)} [OPTIONS] LOG_GROUP_NAME LOG_BUCKET_NAME

Download all CloudWatch Logs for the specified time window from the specified log group,
and upload them to LOG_BUCKET_NAME.

The current working directory will be used for temporary storage of the log
files, which may be very large!

For example:
  # Download logs from prod events.log between 2018-09-21 and 2018-10-10,
  # split them into 5 MiB chunks, and then upload them to S3 under
  # s3://login-gov-prod-logs/imported_from_cloudwatch_logs/events.log/.
  # Don't delete them afterwards in case it's useful to go through them.
  #{File.basename($0)} -s 1537574400 -e 1539214898 --split-bytes 5242880 --skip-delete prod_/srv/idp/shared/log/events.log login-gov-prod-logs

  # Download logs from prod events.log between 2018-09-21 and 2018-10-10, but
  # keep them locally and don't upload them. This is useful if the files need
  # to be manually split before uploading.
  #{File.basename($0)} -s 1537574400 -e 1539214898 --dry-run --skip-delete prod_/srv/idp/shared/log/events.log login-gov-prod-logs

  # Download logs from prod events.log between 2018-09-21 and 2018-10-10, but
  # keep them locally and don't upload them. This is useful if the files need
  # to be manually split before uploading.
  #{File.basename($0)} -s 1537574400 -e 1539214898 --dry-run --skip-delete prod_/srv/idp/shared/log/events.log login-gov-prod-logs

  # Download logs from prod events.log between 2018-09-21 and 2018-10-10, and
  # upload them to s3://login-gov-prod-logs/...
  #{File.basename($0)} -s 1537574400 -e 1539214898 prod_/srv/idp/shared/log/events.log login-gov-prod-logs

Options:
    EOM

    opts.on('-h', '--help', 'Display this message') do
      STDERR.puts opts
      exit
    end

    opts.on('-s', '--start-time STAMP',
            'Start time in seconds since the epoch') do |timestamp|
      reupload_options[:start_time] = Time.at(Float(timestamp)).utc
    end

    opts.on('-e', '--end-time STAMP',
            'End time in seconds since the epoch') do |timestamp|
      reupload_options[:end_time] = Time.at(Float(timestamp)).utc
    end

    opts.on('-S', '--skip STREAM',
            'List of log streams (space separated) to ignore') do |streams|
      reupload_options[:skip_streams] ||= Set.new
      reupload_options[:skip_streams] += streams.split(' ')
    end

    opts.on('-Z', '--split-bytes SIZE',
            'Split output files into chunks <= SIZE bytes.') do |val|
      reupload_options[:split_bytes] = Integer(val)
    end

    opts.on('--s3-prefix KEY',
            'S3 prefix for uploading imported logs') do |val|
      reupload_options[:s3_key_prefix] = val
    end

    opts.on('-n', '--dry-run', "Download but don't upload logs") do
      reupload_options[:dry_run] = true
    end

    opts.on('--skip-delete', "Don't delete files after uploading them") do
      reupload_options[:skip_delete] = true
    end
  end
  # rubocop:enable Metrics/BlockLength

  args = optparse.parse(ARGV)

  if args.length != 2
    STDERR.puts(optparse)
    STDERR.puts('Must pass 2 args')
    exit 1
  end

  log_group_name, log_bucket_name = args

  em = EventMover.new(log_group_name: log_group_name,
                      log_bucket_name: log_bucket_name)
  em.download_and_reupload_time_window(**reupload_options)
end

if $0 == __FILE__
  main
end
