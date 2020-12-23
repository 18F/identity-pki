module Health
  class CertsController < ApplicationController
    newrelic_ignore_apdex

    def index
      result = health_checker.check_certs(deadline: deadline)

      render json: result.as_json,
             status: result.healthy? ? :ok : :service_unavailable
    end

    private

    def health_checker
      @health_checker ||= HealthChecker.new
    end

    def deadline
      DurationParser.new(params[:deadline]).parse&.from_now ||
        Time.zone.parse(params[:deadline].to_s) ||
        30.days.from_now
    end
  end
end
