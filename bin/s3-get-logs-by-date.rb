#!/usr/bin/env ruby

require 'bundler/setup'

require 'aws-sdk-s3'
require_relative '../cloudlib/lib/cloudlib'

def usage
  STDERR.puts <<-EOM
usage: #{File.basename($0)} BUCKET DATE [--download]

Download all log files for BUCKET on DATE to the current directory.

If BUCKET has logs under elk/<DATE>/, then download all of those logs. If it
doesn't, look for prepared file listings under aa_file_list/ so that we
don't have to list the entire bucket's root contents. Then download the named
files which are commingled at the root directory.

If --download is not given, just list the files that would be downloaded.
EOM
end

class LogDownloader
  attr_reader :s3

  DateRegex = /(?<date>\d{4}-\d{2}-\d{2})T\d{2}/
  DateTimeRegex = /(?<datetime>(?<date>\d{4}-\d{2}-\d{2})T\d{2}\.\d{2})/

  def initialize
    @s3 = s3_client_create
  end

  def log
    @log ||= Cloudlib.class_log(self.class, STDERR)
  end

  def s3_client_create
    Aws::S3::Client.new
  end

  def copy_object(source_bucket:, source_key:, target_bucket:, target_key:)
    s3.copy_object(copy_source: source_bucket + '/' + source_key,
                   bucket: target_bucket, key: target_key)
  end

  def download_file(bucket:, key:)
    url = "s3://#{bucket}/#{key}"
    basename = File.basename(key)
    log.debug("Downloading #{url.inspect} to #{basename.inspect}")

    s3.get_object(bucket: bucket, key: key, response_target: basename)
  rescue Aws::S3::Errors::NoSuchKey
    log.error("No such key: #{url.inspect}")
    raise
  end

  def extract_datetime(filename, raise_error: true)
    match = DateTimeRegex.match(filename)

    unless match
      if raise_error
        raise Cloudlib::NotFound.new("No date found in #{filename.inspect}")
      else
        return '0000-00-00'
      end
    end

    match['datetime']
  end

  def download_files(bucket:, keys:, dry_run: false)
    keys.sort_by! { |k| extract_datetime(k, raise_error: false) }

    log.info("Downloading files from #{bucket.inspect}:")

    files_indented = keys.map { |k| '  ' + k }.join("\n")
    puts files_indented

    if dry_run
      log.info("Rerun with --download to download these files")
      return
    end

    total = keys.length
    pct_printed = 0
    missing_files = []

    keys.each_with_index do |key, i|
      pct = 100 * i / total
      if pct > pct_printed
        log.debug("#{pct}% complete (#{i}/#{total})")
        pct_printed = pct
      end

      begin
        download_file(bucket: bucket, key: key)
      rescue Aws::S3::Errors::NoSuchKey
        missing_files << key
      end
    end

    unless missing_files.empty?
      log.error("Could not find these keys in S3:\n  " +
                missing_files.join("\n  "))
    end
  end

  def download_date_prefixed(bucket, date, dry_run: true)
    prefix = "elk/#{date}/"
    log.debug("Looking for logs at s3://#{bucket}/#{prefix}")

    query = {
      bucket: bucket, prefix: prefix, delimiter: '/', max_keys: 1000,
    }
    resp = s3.list_objects_v2(**query)
    if resp.contents.empty?
      raise Cloudlib::NotFound.new(
        "No files found in #{bucket.inspect} at #{prefix}"
      )
    end

    all_files = resp.contents
    while resp.is_truncated
      resp = s3.list_objects_v2(**query,
        continuation_token: resp.next_continuation_token)
      all_files.concat(resp.contents)
    end

    log.debug("Found #{all_files.length} files")

    download_files(bucket: bucket, keys: all_files.map(&:key),
                   dry_run: dry_run)

    log.debug('Finished downloading date prefixed files') unless dry_run
  end

  def get_prepared_listing_for_date(bucket, date)
    key = "aa_file_list/listing.#{date}.txt"
    log.debug("Getting file list for #{date.inspect} at s3://#{bucket}/#{key}")

    resp = s3.get_object(bucket: bucket, key: key)
    resp.body.read
  end

  def parse_prepared_file_list(content)
    content.split("\n").map { |line|
      line.split(' ', 4).last
    }
  end

  def download_from_listing(bucket, date, dry_run: true)
    raw_file_list = get_prepared_listing_for_date(bucket, date)
    files = parse_prepared_file_list(raw_file_list)

    log.debug("Found #{files.length} files in prepared listing")

    download_files(bucket: bucket, keys: files, dry_run: dry_run)

    unless dry_run
      log.debug('Finished downloading files from pre-prepared listing')
    end
  end

  def main(bucket, date, arg3=nil)
    unless date =~ /\A\d{4}-\d{2}-\d{2}\z/
      raise ArgumentError.new("Invalid date: #{date.inspect}")
    end

    dry_run = true
    if arg3
      if arg3 == '--download'
        dry_run = false
      else
        usage
        exit 2
      end
    end

    begin
      download_date_prefixed(bucket, date, dry_run: dry_run)
    rescue Cloudlib::NotFound
      log.info('Could not find files prefixed by date')
      download_from_listing(bucket, date, dry_run: dry_run)
    end
  end
end

if __FILE__ == $0
  if ARGV.length < 2 || ARGV.length > 3
    usage
    exit 1
  end
  LogDownloader.new.main(*ARGV)
end
