#!/usr/bin/env ruby
require 'active_support/time'
require 'optparse'

TIME_FORMAT = "%Y-%m-%d %I:%M %p"

def message(date, duration, state)
  duration = duration.to_i
  # ensure a TZ is set and correctly set other zone offsets
  eastern = ActiveSupport::TimeZone['America/New_York'].parse(date)
  utc = eastern.in_time_zone('UTC')
  central = eastern.in_time_zone('America/Chicago')
  mountain = eastern.in_time_zone('America/Denver')
  pacific = eastern.in_time_zone('America/Los_Angeles')
  template = <<-EOM

  [Planned Maintenance] Login.gov identity verification services unavailable for residents of #{state}

  Impact: Low - Downstream provider maintenance for a subset of Identity Verification users

  Maintenance Window:
  UTC: #{utc.strftime(TIME_FORMAT)} to #{(utc + duration.hours).strftime(TIME_FORMAT)}
  Eastern:  #{eastern.strftime(TIME_FORMAT)} to #{(eastern + duration.hours).strftime(TIME_FORMAT)}
  Central:  #{central.strftime(TIME_FORMAT)} to #{(central + duration.hours).strftime(TIME_FORMAT)}
  Mountain: #{mountain.strftime(TIME_FORMAT)} to #{(mountain + duration.hours).strftime(TIME_FORMAT)}
  Pacific:  #{pacific.strftime(TIME_FORMAT)} to #{(pacific + duration.hours).strftime(TIME_FORMAT)}

  #{state} state driver's license information will be unavailable during this planned maintenance.  Users who experience a problem with identity verification are asked to try again after the maintenance window has closed.

  All other Login.gov functionality will continue to operate normally during this window.

  Partners may submit any questions or concerns through our Partner Support system: https://logingov.zendesk.com/

  EOM
  template
end

def main(args)
  basename = File.basename($0)
  date = DateTime.now.beginning_of_hour.strftime(TIME_FORMAT)
  duration = rand(6) + 1
  state = 'Washington'
  # print help if args are empty
  ARGV << '-h' if ARGV.empty?
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
    Usage: #{basename} -t #{date} -d #{duration} -s #{state}

    EOM
    opts.on('-t', '--datetime=DATETIME', 'maintenance start date and time in ET') { |t| options[:date] = t }
    opts.on('-d', '--duration=DURATION', 'duraiton in hours') { |h| options[:duration] = h }
    opts.on('-s', '--state=STATE', 'set name of state') { |s| options[:state] = s }
    opts.on('-h', '--help', 'prints this help') do
      puts opts
      puts "\nOutput:\n #{message(date, duration, state)}"
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