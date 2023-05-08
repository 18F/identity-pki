# frozen_string_literal: true

# frozen_string_literal: true.
# Top level module for KMS Monitoring
module IdentityKMSMonitor
end

require_relative './kms_monitor/cloudtrail'
require_relative './kms_monitor/cloudwatch'
require_relative './kms_monitor/events_generator'
