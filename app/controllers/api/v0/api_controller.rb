# frozen_string_literal: true

module Api::V0
  class ApiController < ActionController::API
    include ErrorHandler

    before_action :authenticate_user!

    attr_reader :current_user, :decoded_token

    private

    def authenticate_user!
      current_user, decoded_token = Jwt::Authenticator.call(
        headers: request.headers,
        cookies: request.cookies
      ).data

      @current_user ||= current_user
      @decoded_token ||= decoded_token
    end
  end
end
