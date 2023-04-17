require 'sinatra/base'
require 'logger'

module Salesforcelib
  # A super-simple localhost server that is meant to catch OAuth callbacks
  # Use ::wait_for_callback! to start a server, then return the "code" query param
  # that is redirected to
  class Server < Sinatra::Base
    set :port, 8888
    set :quiet, true
    set :server_settings, {
      Logger: Logger.new('/dev/null'),
      AccessLog: Logger.new('/dev/null'),
    }

    CALLBACK = '/callback'
    QUEUE = Queue.new

    def self.redirect_uri
      URI.join("http://localhost:#{port}", CALLBACK)
    end

    # @return [String] the "code" callback param value
    def self.wait_for_callback!
      Thread.new { run! }
      value = QUEUE.pop
      quit!

      value
    end

    get CALLBACK do
      if params['code']
        Thread.new { sleep 0.1; QUEUE << params['code'] }

        <<~HTML
          <!doctype HTML>
          <html>
            <head>
              <title>Authorized</title>
            </head>
            <body>
              <h1>You have successfully authorized Salesforce</h1>

              <p>Close this window and go back to the terminal.</p>
            </body>
          </html>
        HTML
      else
        "No ?code param detected"
      end
    end
  end
end
