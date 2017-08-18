#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'erb'
require 'ostruct'

input = JSON.parse(ARGF.read)

if !input.key?("erb_template")
  raise "The key erb_template is required and is expected to be an erb template string."
end

erb_template = input.delete("erb_template")

def erb(template, vars)
    ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
end

output = {
  "rendered" => erb(erb_template, input)
}

puts output.to_json
