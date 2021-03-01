class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # For lograge
  def append_info_to_payload(payload)
    payload[:user_agent] = request.user_agent
    payload[:ip] = request.remote_ip
    payload[:host] = request.host
    payload[:trace_id] = request.headers['X-Amzn-Trace-Id']
  end
end
