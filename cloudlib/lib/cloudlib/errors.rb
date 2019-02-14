# frozen_string_literal: true

module Cloudlib
  # Base class for Cloudlib errors
  class Error < ::StandardError; end
  class ManyFound < Error; end
  class NotFound < Error; end
  class UnsafeError < Error; end

  # Base class for all CLI reportable errors
  class CLIError < Error; end

  # CWD is not a cloudlib lambda repository
  class NotInRepository < CLIError; end
end
