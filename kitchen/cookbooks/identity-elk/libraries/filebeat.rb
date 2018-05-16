require 'resolv'
require 'socket'
require 'timeout'

class Chef
  class Recipe

    # returns true if logstash has a filebeat port open, otherwise returns false
    def logstash_listening?(hostname)
      begin
        Timeout::timeout(1) do
          begin
            ip = Resolv.getaddress(hostname)
            s = TCPSocket.new(ip, 5044)
            s.close
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Resolv::ResolvError, SocketError
            return false
          end
        end
      rescue Timeout::Error
      end

      return false
    end

    def find_active_logstash
      # if ASG is online, use ASG logstash
      if logstash_listening?('logstash.login.gov.internal')
        return 'logstash.login.gov.internal:5044'
      # else if legacy is online, use legacy
      elsif logstash_listening?('elk.login.gov.internal')
        return 'elk.login.gov.internal:5044'
      # else use ASG logstash
      else
        return 'logstash.login.gov.internal:5044'
      end
    end

  end
end
