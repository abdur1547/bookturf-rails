# frozen_string_literal: true

module ApiAuthHelpers
  # Extract JWT token from response headers
  # @param response [ActionDispatch::TestResponse] The response object
  # @return [String, nil] The JWT token or nil
  def extract_token_from_response(response)
    response.headers['Authorization']&.split(' ')&.last
  end

  # Create authorization header with JWT token
  # @param token [String] The JWT token
  # @return [Hash] Headers hash with Authorization
  def auth_headers(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  # Sign in a user and return the JWT token
  # @param user [User] The user to sign in
  # @param password [String] The user's password
  # @return [String] The JWT token
  def api_sign_in(user, password = 'password')
    post '/api/v0/auth/sign_in', params: {
      user: {
        email: user.email,
        password: password
      }
    }, as: :json

    extract_token_from_response(response)
  end

  # Authenticate a user for request specs
  # @param user [User] The user to authenticate
  # @param password [String] The user's password (default: 'password')
  # @return [Hash] Headers with Authorization token
  def authenticate_user(user, password = 'password')
    token = api_sign_in(user, password)
    auth_headers(token)
  end
end

RSpec.configure do |config|
  config.include ApiAuthHelpers, type: :request
end
