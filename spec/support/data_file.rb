module DataFileHelpers
  ROOT_DIR = File.dirname(__FILE__)

  def data_file(filename)
    full_path = File.join(ROOT_DIR, '..', 'data', filename)
    IO.binread(full_path) if File.exist?(full_path)
  end
end

RSpec.configure do |c|
  c.include DataFileHelpers
end
