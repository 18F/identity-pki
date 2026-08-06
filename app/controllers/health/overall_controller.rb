module Health
  # Hosts endpoints used by the load balancer to detect if an instance is healthy
  class OverallController < ApplicationController
    newrelic_ignore_apdex

    def index
      render plain: 'success'
    end
  end
end
