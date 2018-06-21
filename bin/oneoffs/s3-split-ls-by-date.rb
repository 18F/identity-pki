#!/usr/bin/env ruby

def usage
  STDERR.puts <<-EOM
usage: #{File.basename($0)} S3_LISTING OUT_DIRECTORY

Run through S3_LISTING, which should be the output of \`aws s3 ls\`, and split
out each entry by its modification date into separate listing files in
OUT_DIRECTORY.
  EOM
end

def create_file_noclobber(filename)
  puts "Creating #{filename.inspect}"
  File.open(filename, File::WRONLY | File::CREAT | File::EXCL)
end

if ARGV.length != 2
  usage
  exit 1
end

infile = ARGV.fetch(0)
outdir = ARGV.fetch(1).chomp('/')

puts "Splitting #{infile.inspect} by date into #{outdir.inspect}"

# keep output file handles around to minimize system calls
out_handles = {}

# Increase our file handle limit
cur_rlimit = Process.getrlimit(:NOFILE).first
puts "rlimit NOFILE: #{cur_rlimit}"
Process.setrlimit(:NOFILE, 1024) if cur_rlimit < 1024

File.open(infile, 'r') do |inf|
  inf.each_line do |line|
    date, rest = line.split(' ', 2)

    next if date.empty? || date == 'PRE'

    outfile = "#{outdir}/listing.#{date}.txt"
    begin
      out_handles[outfile] ||= create_file_noclobber(outfile)
    rescue Errno::EMFILE
      STDERR.puts 'Hit EMFILE, closing all file handles'
      out_handles.values.map(&:close)
      out_handles.clear
      retry
    end

    out_handles.fetch(outfile) << date + ' ' + rest
  end
end

out_handles.values.map(&:flush)

puts 'Finished'

# don't bother garbage collecting, just bail out real fast
exit!
