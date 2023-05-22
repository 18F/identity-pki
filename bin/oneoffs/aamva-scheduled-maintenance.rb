#!/usr/bin/env ruby
require 'active_support/time'
require 'date'
require 'optparse'

def main(args)
  basename = File.basename($0)

  # print help if args are empty
  ARGV << '-h' if ARGV.empty?
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = <<-EOM
    Usage: #{basename} -s 'Washington' -t '2023-05-21 05:00 AM' -d 4

    output:
    [Planned Maintenance] Login.gov identity verification services unavailable for residents of Washington
    
    Impact: Low - Downstream provider maintenance for a subset of Identity Verification users
    
    Maintenance Window:
    UTC: 2023-05-21 7:00 AM to 2023-05-21 2:00 PM
    Eastern:  2023-05-21  3:00 AM to 10:00 AM
    Central:  2023-05-21  2:00 AM to 9:00 AM
    Mountain: 2023-05-21  1:00 AM to 8:00 AM
    Pacific:  2023-05-21 12:00 AM to 7:00 AM
    
    Washington state driver's license information will be unavailable during this planned maintenance.  Users who experience a problem with identity verification are asked to try again after the maintenance window has closed.
    
    All other Login.gov functionality will continue to operate normally during this window.
    
    Partners may submit any questions or concerns through our Partner Support system: https://logingov.zendesk.com/
    
    EOM
    opts.on('-s', '--state=STATE', 'set name of state') { |s| options[:state] = s }
    opts.on('-t', '--datetime=DATETIME', 'maintenance start date and time in ET') { |t| options[:date] = t }
    opts.on('-d', '--duration=DURATION', 'duraiton in hours') { |h| options[:duration] = h }
    opts.on('-h', '--help', 'prints this help') do
      puts opts
      exit
    end
  
  end

  args = optparse.parse!

  # ensure a TZ is set and correctly set other zone offsets
  eastern = ActiveSupport::TimeZone['America/New_York'].parse(options[:date])

  utc = eastern.in_time_zone('UTC')
  central = eastern.in_time_zone('America/Chicago')
  mountain = eastern.in_time_zone('America/Denver')
  pacific = eastern.in_time_zone('America/Los_Angeles')

  duration = options[:duration].to_i
  time_format = "%Y-%m-%d %I:%M %p"

  message = <<-EOM
[Planned Maintenance] Login.gov identity verification services unavailable for residents of #{options[:state]}

Impact: Low - Downstream provider maintenance for a subset of Identity Verification users

Maintenance Window:
UTC: #{utc.strftime(time_format)} to #{(utc + duration/24r).strftime(time_format)}
Eastern:  #{eastern.strftime(time_format)} to #{(eastern + duration/24r).strftime(time_format)}
Central:  #{central.strftime(time_format)} to #{(central + duration/24r).strftime(time_format)}
Mountain: #{mountain.strftime(time_format)} to #{(mountain + duration/24r).strftime(time_format)}
Pacific:  #{pacific.strftime(time_format)} to #{(pacific + duration/24r).strftime(time_format)}

#{options[:state]} state driver's license information will be unavailable during this planned maintenance.  Users who experience a problem with identity verification are asked to try again after the maintenance window has closed.

All other Login.gov functionality will continue to operate normally during this window.

Partners may submit any questions or concerns through our Partner Support system: https://logingov.zendesk.com/
EOM

  puts message
end

# only execute code if this script is run on its own 
if $PROGRAM_NAME == __FILE__
  main(ARGV)
end
