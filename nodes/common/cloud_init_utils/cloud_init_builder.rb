#!/usr/bin/env ruby

require 'mime'
require 'erb'
require 'ostruct'

def load_template(template_path, vars)
  template = File.read(template_path)
  ERB.new(template).result(OpenStruct.new(vars).instance_eval { binding })
end

def build_cloud_init(file_info_objects)
  combined_msg = MIME::Multipart::Mixed.new
  file_info_objects.each do |file_info_object|
    content = load_template(file_info_object.fetch("template"), file_info_object.fetch("vars"))
    text_media = MIME::Text.new(content, file_info_object.fetch("content_type").split("/", 2)[1])
    text_media.disposition = "attachment; filename=\"#{file_info_object.fetch('filename')}\""
    text_media.transfer_encoding = Encoding.default_external
    text_media.mime_version = "1.0"
    combined_msg.add(text_media)
  end
  combined_msg.to_s
end

def main()
  if ARGV.length < 1
    puts "#{ARGV[0]} input-file:type ..."
    exit(1)
  end
  combined_msg = build_cloud_init(ARGV.map { |arg|
    filename, format_type = arg.split(":", 2)
    { "template" => filename, "filename" => File.basename(filename), "content_type" => format_type, "vars" => {} }})
  puts combined_msg.to_s
end

if __FILE__ == $0
  main
end
