Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/', to: 'identify#create'
  post '/', to: 'verify#open'

  get '/health_check' => 'health/overall#index'
  get '/api/health/certs' => 'health/certs#index'
end
