module Cloudlib
  # Base class for Cloudlib errors
  class Error < ::StandardError; end
  class ManyFound < Error; end
  class NotFound < Error; end
end
