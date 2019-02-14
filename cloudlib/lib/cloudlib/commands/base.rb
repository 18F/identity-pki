# frozen_string_literal: true

module Cloudlib
  module Commands
    # Base class for Cloudlib CLI commands
    class Base < Thor
      # Thor has an insane default where it doesn't exit with failure upon
      # hitting fatal errors.
      # https://github.com/erikhuda/thor/issues/244
      def self.exit_on_failure?
        true
      end
    end
  end
end
