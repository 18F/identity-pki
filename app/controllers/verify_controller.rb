require 'base64'
require 'cgi'
require 'openssl'

class VerifyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def open
    token = params.require(:token)
    hmac = request.headers['HTTP_AUTHENTICATION']
    render json: TokenService.open(token, hmac)
  rescue ActionController::ParameterMissing
    render json: { error: 'token.missing' }
  end
end
