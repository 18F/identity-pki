#!/usr/bin/env ruby
#
# This script can be used to calculate the amount of logs we ingest into ELK
# in the last 30 days.  Auditors seem to want to know the answer to this
# every once in a while, so while finding this out, I wrote a script.
#
# A way to use it is:
#
# curl -sk https://localhost:9200/_cat/indices?v | grep logstash | grep -v .monitoring-logstash | ./esusage.rb
#
# I am actually just cut/pasting the output of the curl into the command and
# running it on my laptop, where I have the filesize gem installed.  But this
# should give you an idea of how to collect the data and then how to feed it
# to the script.
#

require 'date'
require 'filesize'

totallines = 0
totaldiskspace = Filesize.from("0B")

ARGF.each do |line|
	# get line
	data = line.split(/\s+/)

	# skip if not in last 30 days
	datestring = data[2].split(/-/).last
	indexdate = Date.strptime(datestring, '%Y.%m.%d')
	next if indexdate < Date.today - 30

	# add log lines
	totallines = totallines + data[6].to_i

	# add disk space
	diskspace = Filesize.from(data[9])
	totaldiskspace = totaldiskspace + diskspace
end

puts "total log messages handled in the last 30 days: #{totallines}"
puts "total non-redundant disk space used by messages handled in the last 30 days: #{totaldiskspace.pretty}"

