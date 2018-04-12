module DataFileHelpers
  ROOT_DIR = File.dirname(__FILE__)

  def data_file(filename)
    full_path = data_file_path(filename)
    IO.binread(full_path) if File.exist?(full_path)
  end

  def data_file_path(filename)
    File.join(ROOT_DIR, '..', 'data', filename)
  end
end

RSpec.configure do |c|
  c.include DataFileHelpers
end
