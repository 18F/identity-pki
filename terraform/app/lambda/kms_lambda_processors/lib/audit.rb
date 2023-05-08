# frozen_string_literal: true

# Top level module for audits
module IdentityAudit
end

require_relative './audit/aws'
require_relative './audit/config'
require_relative './audit/github'
require_relative './audit/repo_content'
