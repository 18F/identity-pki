require 'cgi'
require 'openssl'

class VerifyController < ApplicationController
  skip_before_action :verify_authenticity_token

  def open
    # TODO: secure this endpoint against public use
    token = params.require(:token)
    render json: TokenService.open(token)
  rescue ActionController::ParameterMissing
    render json: { error: 'token.missing' }
  end
end
