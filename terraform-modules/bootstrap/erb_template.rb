#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'json'
require 'erubis'

def usage
  STDERR.puts <<-EOM
usage: #{$0} [FILE]

Render an ERB template using the Terraform External Program Protocol for
receiving input and writing output.

Read JSON on STDIN or from FILE. Expect a key "erb_template", whose value is an
ERB template string. This string will be evaluated as an ERB template and
passed all other keys from the input JSON as variables.

The resulting template will be written to STDOUT as JSON:
{
  "rendered": "..."
}
  EOM
end

if ARGV.empty? && STDIN.tty?
  usage
  exit 1
end

input = JSON.parse(ARGF.read)

unless input.is_a?(Hash)
  usage
  raise 'Input is not a JSON hash'
end

erb_template = input.delete('erb_template')

unless erb_template
  usage
  raise 'The key erb_template is required and is expected to be an erb template string.'
end

def erb(template, vars)
  #ERB.new(template).result_with_hash(vars)
  #ERB.new(template, trim_mode: '-').result_with_hash(vars)
  Erubis::Eruby.new(template).result(vars)
end

output = {
  "rendered" => erb(erb_template, input)
}

puts output.to_json
