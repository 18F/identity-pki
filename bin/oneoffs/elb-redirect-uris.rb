#!/usr/bin/env ruby
# frozen_string_literal: true

require 'cgi'
require 'csv'
require 'optparse'
require 'set'
require 'yaml'
require 'zlib'

require 'bundler/setup'
require 'aws-sdk-s3'
require 'json'

# ALB log format:
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
ALB_FIELDS = %w[
  type
  timestamp
  elb
  client:port
  target:port
  request_processing_time
  target_processing_time
  response_processing_time
  elb_status_code
  target_status_code
  received_bytes
  sent_bytes
  request
  user_agent
  ssl_cipher
  ssl_protocol
  target_group_arn
  trace_id
  domain_name
  chosen_cert_arn
  matched_rule_priority
  request_creation_time
  actions_executed
].freeze

ALB_INDEX_MAP = {}
ALB_FIELDS.each_with_index do |field, index|
  ALB_INDEX_MAP[field] = index
end
ALB_INDEX_MAP.freeze

NULL_FIELD = '-'

# Regex adapted from
# https://docs.aws.amazon.com/athena/latest/ug/application-load-balancer-logs.html
ALB_REGEX = %r[
  \A
  (?<type>[^ ]*)
  \p{Space}
  (?<timestamp>[^ ]*)
  \p{Space}
  (?<elb>[^ ]*)
  \p{Space}
  (?<client_port>[^ ]*:[0-9]*)
  \p{Space}
  # old ALB logs from 2017 don't necessarily have target port
  (?<target_port>[^ ]*([:-](?<target_port_number>[0-9]*))?)
  \p{Space}
  (?<request_processing_time>[\.0-9-]*)
  \p{Space}
  (?<target_processing_time>[\.0-9-]*)
  \p{Space}
  (?<response_processing_time>[\.0-9-]*)
  \p{Space}
  (?<elb_status_code>|[0-9-]*)
  \p{Space}
  (?<target_status_code>-|[0-9-]*)
  \p{Space}
  (?<received_bytes>[0-9-]*)
  \p{Space}
  (?<sent_bytes>[0-9-]*)
  \p{Space}
  "(?<request>[^"]*)"
  \p{Space}
  "(?<user_agent>[^"]*)"
  \p{Space}
  (?<ssl_cipher>[A-Z0-9()-]+)
  \p{Space}
  (?<ssl_protocol>[A-Za-z0-9.-]*)
  \p{Space}
  (?<target_group_arn>[^ ]*)
  \p{Space}
  "(?<trace_id>[^"]*)"
  # All of the fields from here on out are optional for backwards compatibility
  # with older log files
  ( \p{Space}
    "(?<domain_name>[^"]*)"
    ( \p{Space}
      "(?<chosen_cert_arn>[^"]*)"
      ( \p{Space}
        (?<matched_rule_priority>[\.0-9-]*)
        ( \p{Space}
          (?<request_creation_time>[^ ]*)
          ( \p{Space}
            "(?<actions_executed>[^"]*)"
            ( \p{Space}
              "([^ ]*)"
            )?
          )?
        )?
      )?
    )?
  )?
]x

# Return a prefix of ALB_REGEX that only has the specified number of parts.
# This is useful for figuring out where in the regex things are going wrong
# given a log line that the regex failed to match.
def alb_regex_partial(n_parts)
  split = ALB_REGEX.to_s.split("\n")
  new_s = (split[0..n_parts] + [split.last]).join("\n")
  Regexp.new(new_s, Regexp::EXTENDED)
end

class RedirectUriSearcher
  attr_reader :bucket
  attr_reader :evil_redirect_uris
  attr_reader :invalid_uris
  attr_reader :prefix
  attr_reader :s3
  attr_reader :seen_dates
  attr_reader :seen_redirect_uris

  VulnerablePrefixes = [
    'https://sp-oidc-sinatra',
    'https://ttp.cbp.dhs.gov',
    'https://my.move.mil',
    'https://tsp.move.mil',
    'https://office.move.mil',
  ].freeze

  def initialize(bucket:, prefix:)
    unless prefix.include?('/AWSLogs/')
      raise ArgumentError.new("Expected #{prefix.inspect} to include /AWSLogs/")
    end
    unless prefix.include?('/elasticloadbalancing/')
      raise ArgumentError.new("Expected #{prefix.inspect} to include /elasticloadbalancing/")
    end
    prefix += '/' unless prefix.end_with?('/')

    @seen_redirect_uris = {}
    @evil_redirect_uris = Set.new
    @invalid_uris = Set.new
    @seen_dates = []
    @s3 = s3_client_create
    @bucket = bucket
    @prefix = prefix
    @interrupted = false

    # make sure all the vulnerable prefixes can be parsed
    VulnerablePrefixes.map {|v| URI.parse(v) }
  end

  def interrupted?
    @interrupted
  end

  def interrupted!
    @interrupted = true
    log.warn('Interrupted')
    puts 'WARNING: Interrupted, results are incomplete'
  end

  def evil_redirect_uri?(raw_uri)
    VulnerablePrefixes.each do |vuln_prefix|
      next unless raw_uri.start_with?(vuln_prefix)

      begin
        parsed = URI.parse(raw_uri)
      rescue URI::Error
        # assume invalid URIs are evil
        return true
      end
      v_parsed = URI.parse(vuln_prefix)

      return true if parsed.host != v_parsed.host
    end

    false
  end

  def log
    return @log if @log
    @log = Logger.new(STDERR)
    @log.level = Logger::INFO
    @log
  end

  def s3_client_create
    # TODO set region
    Aws::S3::Client.new
  end

  def maybe_add_evil(redirect_uri, line)
    return false unless evil_redirect_uri?(redirect_uri)

    evil_redirect_uris << redirect_uri
    log.warn("FOUND NEW EVIL URI: #{redirect_uri.inspect}")
    log.warn("Full line: #{line.inspect}")
  end

  def process_redirect_uris(string:)
    string.each_line do |line|
      process_redirect_uri_line(line.strip)
    end
  end

  def process_redirect_uri_line(line)
    # search only GET requests
    return unless line.include?('"GET')

    #data = CSV.parse(line, col_sep: ' ')
    #if data.length != 1
    #  raise "Unexpected # of rows in CSV parsing of data: #{line.inspect}"
    #end
    #row = data.first

    match = ALB_REGEX.match(line)
    unless match
      log.fatal("Could not parse line with regex")
      log.fatal("Line: #{line.inspect}")
      raise "Regex failed to parse #{line.inspect}"
    end

    # skip requests that received 4xx errors
    #return if row.fetch(ALB_INDEX_MAP.fetch('elb_status_code')).start_with?('4')
    return if match['elb_status_code'].start_with?('4')

    #request = row.fetch(ALB_INDEX_MAP.fetch('request'))
    request = match['request']
    parts = request.split(' ')
    if parts.length != 3
      log.debug { "Invalid HTTP request line: #{parts.inspect}" }
      log.debug { "Full log line: #{line.inspect}" }
      invalid_uris << line
      return
    end

    raw_uri = parts.fetch(1)

    begin
      request_uri = URI.parse(raw_uri)
    rescue URI::Error
      log.debug { "Invalid URI: #{raw_uri.inspect}" }
      log.debug { "From line: #{line.to_json}" }
      invalid_uris << raw_uri
      return
    end

    # TODO: determine whether this is reasonable to exclude
    return if request_uri.path != '/openid_connect/authorize'

    # skip if no query string
    return unless request_uri.query

    # parse the query looking for redirect_uri
    params = CGI.parse(request_uri.query)

    params.fetch('redirect_uri', []).each do |redirect_uri|
      if !seen_redirect_uris.include?(redirect_uri)
        log.info("Found new redirect URI: #{redirect_uri.inspect}")
        STDOUT.puts(redirect_uri)
        STDOUT.flush
        maybe_add_evil(redirect_uri, line)
        seen_redirect_uris[redirect_uri] = 1
      else
        seen_redirect_uris[redirect_uri] += 1
      end
    end
  rescue StandardError => err
    log.fatal("While processing a line, hit #{err.inspect}")
    log.fatal("line: #{line.to_json}")
    raise
  end

  # List each file in the S3 bucket under the prefix for the specified date.
  # Yield each full prefix in turn.
  #
  # This method must be passed a block.
  #
  # @param [String] date A date in YYYY-MM-DD format.
  # @yield [Aws::S3::Types::Object] A matching object in S3.
  #
  def each_file(date:)
    date_prefix = date.tr('-', '/')
    full_prefix = prefix + date_prefix + '/'
    log.debug("Looking for logs at s3://#{bucket}/#{full_prefix}")

    query = {
      bucket: bucket, prefix: full_prefix, max_keys: 1000,
    }
    resp = s3.list_objects_v2(**query)
    if resp.contents.empty?
      log.error("No logs found for #{date} at s3://#{bucket}/#{full_prefix}")
      return
    end

    loop do
      resp.contents.each do |obj|
        yield obj
      end

      break unless resp.is_truncated

      # fetch further results
      log.debug('Listing more logs for same day')
      resp = s3.list_objects_v2(**query,
        continuation_token: resp.next_continuation_token)
    end
  end

  def s3_read_file(key, gunzip_body: false)
    log.debug("Downloading s3://#{bucket}/#{key}")
    resp = s3.get_object(bucket: bucket, key: key)

    if gunzip_body
      gunzip_io(resp.body)
    else
      resp.body.string
    end
  end

  # Because ruby has completely insane and broken behavior around multiple
  # concatenated gzip streams (returning only the first one by default), the IO
  # that we are passed must support #seek and #size.
  def gunzip_io(io)
    out = +''

    loop do
      gz = Zlib::GzipReader.new(io)
      out << gz.read

      # Ruby has insane behavior if multiple gzip streams are concatenated
      # (which is totally valid per RFC 1952), and will silently return only
      # the first one unless you check for unused.
      unused = gz.unused
      gz.finish

      adjust = unused.nil? ? 0 : unused.length
      io.pos -= adjust
      return out if io.pos == io.size
    end
  end

  def gunzip_string(string)
    gunzip_io(StringIO.new(string))
  end

  def search_date(date, pattern: nil)
    log.info("searching logs from date #{date}")
    if pattern
      log.info("Limiting to keys that include: #{pattern}")
    end

    seen_dates << date
    files_checked = 0

    each_file(date: date) do |obj|
      if obj.storage_class == 'GLACIER'
        log.error('UH OH: WE HIT A FILE IN GLACIER') # TODO: actually retrieve?
      end

      if pattern && !obj.key.include?(pattern)
        log.debug("Key #{obj.key} excluded by pattern")
        next
      end

      begin
        # download file and uncompress it
        content = s3_read_file(obj.key, gunzip_body: true)

        # search it for redirect_uris and compile results
        log.debug("Searching #{File.basename(obj.key)}")
        process_redirect_uris(string: content)

      # print log file on errors
      rescue StandardError
        log.fatal("Hit error while processing #{obj.inspect}")
        raise
      end

      files_checked += 1
    end

    log.info("finished searching #{files_checked} logs from date #{date}")
  end

  def print_summary
    log.info('Printing summary')
    puts '== Summary =='
    sorted = {}
    seen_redirect_uris.sort_by { |_k, v| -v }.each { |k, v| sorted[k] = v }
    out = {
      dates: seen_dates.sort,
      status: evil_redirect_uris.empty? ? 'OK' : 'EVIL',
      evil_uris: evil_redirect_uris.to_a.sort,
      invalid_uris: invalid_uris.sort,
      redirect_uris: sorted,
    }
    out['INTERRUPTED'] = true if interrupted?
    puts YAML.dump(out)
  end
end

def main(argv)
  options = {}

  basename = File.basename($0)

  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
usage: #{basename} [OPTIONS] BUCKET PREFIX DATE...

Analyze the redirect URIs found on each DATE, using ALB access logs under
S3_PREFIX.

Stream each unique redirect URI found to stdout. When finished, print a summary
including the counts by date for each redirect URI.

https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
Parsed log file fields:
  #{ALB_FIELDS.join(' ')}

For example:

  #{basename} login-gov.elb-logs.<acct-id>-us-west-2 dev/idp/AWSLogs/<acct-id>/elasticloadbalancing/us-west-2/ 2018-07-{10..20}

You also must set the env variable AWS_REGION to the region your S3 bucket is
in. (TODO)

Options:
EOM

    opts.on('-h', '--help', 'Display this message') do
      STDERR.puts opts
      exit
    end

    opts.on('-v', '--verbose', 'Increase log verbosity') do
      options[:verbose] = true
    end

    opts.on('--pattern PAT',
            'Limit downloaded files to those matching PAT') do |pat|
      options[:pattern] = pat
    end
  end

  args = optparse.parse(argv)

  if args.length < 3
    STDERR.puts optparse
    exit 1
  end

  bucket = args.shift
  prefix = args.shift

  # strip off leading /
  if prefix.start_with?('/')
    prefix = prefix[1..-1]
  end

  dates = args

  rus = RedirectUriSearcher.new(bucket: bucket, prefix: prefix)

  rus.log.level = Logger::DEBUG if options[:verbose]

  begin
    dates.each do |date|
      rus.search_date(date, pattern: options[:pattern])
    end
  rescue Interrupt
    rus.interrupted!
  end

  rus.print_summary

  exit 130 if rus.interrupted?
end

if $0 == __FILE__
  main(ARGV)
end
