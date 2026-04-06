# frozen_string_literal: true

module Jwt
  class Authenticator < BaseService
    def call(headers:, cookies:)
      token = authenticate_header(
        headers,
        cookies
      )
      raise ::Auth::MissingTokenError if token.blank?

      decoded_token = Jwt::Decoder.call(access_token: token).data
      raise ::Auth::UnauthorizedError unless decoded_token

      user = authenticate_user_from_token(decoded_token)
      raise ::Auth::UnauthorizedError if user.blank?

      success([ user, decoded_token ])
    end

    def authenticate_header(headers, cookies)
      (headers["Authorization"] || cookies["access_token"])&.split("Bearer ")&.last
    end

    def authenticate_user_from_token(decoded_token)
      raise ::Auth::InvalidTokenError unless decoded_token[:jti].present? && decoded_token[:user_id].present?

      user = User.find(decoded_token.fetch(:user_id))

      user unless BlacklistedToken.exists?(jti: decoded_token[:jti])
    end
  end
end
