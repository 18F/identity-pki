module Health
  class CertsController < ApplicationController
    newrelic_ignore_apdex

    def index
      deadline = params[:deadline].present? ? Time.zone.parse(params[:deadline]) : 30.days.from_now

      result = health_checker.check_certs(deadline: deadline)

      render json: result.as_json,
             status: result.healthy? ? :ok : :internal_server_error
    end

    private

    def health_checker
      @health_checker ||= HealthChecker.new
    end
  end
end
