#!/usr/bin/env ruby
require 'scrypt'

def usage
  puts <<-EOM
usage: #{File.basename($0)} N r p [rounds]
  Benchmark a single set of scrypt parameters
  N, r, p: scrypt parameters in base 10
  rounds: number of trials to perform

usage: #{File.basename($0)} report
  Run a variety of benchmarks, reporting all the results

To run many parallel versions of this program, do something like this:

    parallel -j 4 -i #{$0} 65536 8 1 10 -- {1..4}
EOM
end

# Use this class if you want logging when running scrypt operations
class LoggedEngine < SCrypt::Engine
  def self.__sc_crypt(secret, salt, n, r, p, key_len)
    warn("__sc_crypt(secret=#{secret.gsub(/./, '*')}, salt=#{salt.inspect}, N=#{n.inspect}, r=#{r.inspect}, p=#{p.inspect}, key_len=#{key_len.inspect})")
    super
  end
end

N_vals_pow = [10, 11, 12, 13, 14, 15, 16, 17, 18]
R_vals = [6, 7, 8, 9, 10]
P_vals = [1, 4]

def benchmark(n:, r:, p:, rounds: nil)
  n_pow = Math.log2(n)

  cost_str = "#{n.to_s(16)}$#{r.to_s(16)}$#{p.to_s(16)}$"
  salt = SCrypt::Engine.generate_salt(cost: cost_str)

  if rounds.nil?
    if n > 2**16
      rounds = 5
    else
      rounds = 10
    end
  end

  start_time = Time.now
  rounds.times do
    SCrypt::Engine.hash_secret('a password', salt, 32)
  end
  elapsed = Time.now - start_time

  round_ms = elapsed * 1000.0 / rounds

  puts "N: #{n} (2^#{n_pow.round(1)}), r: #{r}, p: #{p} \t" \
    "#{round_ms.round(1)}ms"
end

def run_report
  N_vals_pow.each do |n_pow|
    R_vals.each do |r|
      P_vals.each do |p|
        benchmark(n: 2**n_pow, r: r, p: p)
      end
    end
  end
end

def main(args)
  case args.length
  when 1
    if args.first == 'report'
      run_report
    else
      usage
      exit 1
    end
  when 3..4
    n, r, p, rounds = args.map {|x| Integer(x) }
    benchmark(n: n, r: r, p: p, rounds: rounds)
  else
    usage
    exit 1
  end
end

if __FILE__ == $0
  main(ARGV)
end
