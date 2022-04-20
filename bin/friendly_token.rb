require 'devise'

# Used by generate_gitlab_secrets to generate API tokens

puts Devise.friendly_token
