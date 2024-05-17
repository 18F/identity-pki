#!/usr/bin/env ruby
require 'active_support'
require 'active_support/time'
require 'optparse'

TIME_FORMAT = "%Y-%m-%d %I:%M %p"

def message(date, duration, state)
  duration = duration.to_f
  # ensure a TZ is set and correctly set other zone offsets
  eastern = ActiveSupport::TimeZone['America/New_York'].parse(date)
  utc = eastern.in_time_zone('UTC')
  central = eastern.in_time_zone('America/Chicago')
  mountain = eastern.in_time_zone('America/Denver')
  pacific = eastern.in_time_zone('America/Los_Angeles')
  alaska = eastern.in_time_zone('America/Juneau')
  hawaii = eastern.in_time_zone('Pacific/Honolulu')
  template = <<-EOM

[Planned Maintenance] Login.gov identity verification services unavailable for residents of #{state}

<strong>Impact</strong> Low - Downstream provider maintenance for a subset of identity verification users

<strong>Maintenance Window</strong>
<tt><strong>UTC</strong> #{utc.strftime(TIME_FORMAT)} to #{(utc + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Eastern</strong> #{eastern.strftime(TIME_FORMAT)} to #{(eastern + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Central</strong> #{central.strftime(TIME_FORMAT)} to #{(central + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Mountain</strong> #{mountain.strftime(TIME_FORMAT)} to #{(mountain + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Pacific</strong> #{pacific.strftime(TIME_FORMAT)} to #{(pacific + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Alaska</strong> #{alaska.strftime(TIME_FORMAT)} to #{(alaska + duration.hours).strftime(TIME_FORMAT)}</tt>
<tt><strong>Hawaii</strong> #{hawaii.strftime(TIME_FORMAT)} to #{(hawaii + duration.hours).strftime(TIME_FORMAT)}</tt>

#{state} state driver's license information will be unavailable during this planned maintenance. Users who experience a problem with identity verification are asked to try again after the maintenance window has closed.

All other Login.gov functionality will continue to operate normally during this window.

Partners may submit any questions or concerns through our Partner Support system: https://logingov.zendesk.com/

  EOM
  template
end

def parse_date_and_time(date, time)
  date = ActiveSupport::TimeZone['America/New_York'].parse(date)
  time_of_day = time.gsub(/\bET\b/, '').strip
  ActiveSupport::TimeZone['America/New_York'].parse(
    "#{date.strftime('%Y-%m-%d')} #{time_of_day}"
  )
end

def parse_single_day(line)
  regex = Regexp.new(
    <<~REGEXP.gsub(/\s+/m, " ").strip,
      AAMVA Operations has been informed that (?<state>.+)
      will not be available to process DLDV transactions on (?<date>.+)
      from (?<start>.+) (to|until) (?<end>.+)
      due to scheduled maintenance
    REGEXP
    Regexp::IGNORECASE
  )
  m = regex.match(line)
  return unless m

  state = m[:state]
  start_time = parse_date_and_time(m[:date], m[:start])
  end_time = parse_date_and_time(m[:date], m[:end])

  return [ state, start_time, end_time ]
end

def parse_multiple_days(line)
  regex = Regexp.new(
    <<~REGEXP.gsub(/\s+/m, " ").strip
      AAMVA Operations has been informed that
      (?<state>.+) will not be available to process DLDV transactions from
      (?<start_time>.+?), (?<start_date>.+) (to|until) (?<end_time>.+?), (?<end_date>.+)
      due to scheduled maintenance.
    REGEXP
  )
  m = regex.match(line)
  return unless m

  state = m[:state]
  start_time = parse_date_and_time(m[:start_date], m[:start_time])
  end_time = parse_date_and_time(m[:end_date], m[:end_time])

  return [ state, start_time, end_time ]
end

def default_options
  return {} if $stdin.tty?

  # Allow piping an email from AAMVA Operations in here

  $stdin.each_line do |line|
    state, start_time, end_time = parse_single_day(line) || parse_multiple_days(line) || []
    next if [state, start_time, end_time].any?(&:nil?)

    duration_in_minutes = (end_time - start_time) / 60

    return {
      state: state,
      date: start_time.strftime(TIME_FORMAT),
      # We want to push this up to the next 30 minute interval, so
      # e.g. 11:59 PM becomes 12:00 AM
      duration: ((duration_in_minutes / 30).ceil * 30) / 60.0
    }
  end

  raise "STDIN did not look like an email from AAMVA operations"
end

def main(args)
  basename = File.basename($0)

  options = default_options

  # print help if args are empty
  ARGV << '-h' if ARGV.empty? && options.values.any?(&:nil?)

  nowish = DateTime.now.beginning_of_hour.strftime(TIME_FORMAT)
  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
    Usage: #{basename} -t #{nowish} -d 5 -s Washington

    EOM
    opts.on('-t', '--datetime=DATETIME', 'maintenance start date and time in ET') { |t| options[:date] = t }
    opts.on('-d', '--duration=DURATION', 'duraiton in hours') { |h| options[:duration] = h }
    opts.on('-s', '--state=STATE', 'set name of state') { |s| options[:state] = s }
    opts.on('-h', '--help', 'prints this help') do
      puts opts
      puts "\nOutput:\n #{message(nowish, 5, 'Washington')}"
      exit
    end
  end
  args = optparse.parse!
  puts message(options[:date], options[:duration], options[:state])
end

# only execute code if this script is run on its own
if $PROGRAM_NAME == __FILE__
  main(ARGV)
end
